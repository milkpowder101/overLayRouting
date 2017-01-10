require_relative 'part2'


$circuitfragTable=Hash.new


def circuit_nextHop(index,circuitID)
  temp=$circuitTalbe[circuitID.to_i]
  if temp == nil
    return nil
  end
  circuit=temp.instance_variable_get(:@circuit)
  array=circuit.split(",")
  index=index.to_i
  return array[index+1]
end

def circuit_prevHop(index,circuitID)
  temp=$circuitTalbe[circuitID.to_i]
  if temp == nil
    return nil
  end
  circuit=temp.instance_variable_get(:@circuit)
  array=circuit.split(",")
  index=index.to_i
  index=index-1
  if array[index]==array[-1]
    return nil
  else
    return array[index]
  end

end

def sendmsg_circuitm(circuitID,message)
    message=message.split(" ")
    destNode=message[-1]
    message.pop()
    message=message.join(" ")
    message=message.prepend("SENDMSG+")
    fragmentation_circuitm(message,$maxPayload,"SENDMSG",0,circuitID,destNode)
end

def ftp_circuitm(circuitID,information)
    cmd=information.split(" ")
    destNode=cmd.pop()
    fileName=cmd[0]
    filePath=cmd[1]
    fileSize=File.size(fileName)
    currTime=$time

    file = File.open(fileName, "rb")
    contents = file.read

    contents=contents.gsub("\n","(NEWLINE)")
    contents=contents.gsub("\s","(SPACE)")
    contents=contents.gsub("\t","(TAB)")

    str="FTP+#{circuitID}+#{fileName}+#{filePath}+#{currTime}+#{contents}"

    fragmentation_circuitm(str,$maxPayload,"FTP,#{fileSize},#{filePath},#{fileName}",0,circuitID,destNode)
end

def fragmentation_circuitm(message,maxSize,option,index,circuitID,destNode)
  counter=0
  arry=Array.new
  destNode=destNode
  if message.length == 0
    return arry,counter
  end
  while message.length > 0
    x=message.slice!(0,maxSize)
    arry<<x
    counter=counter+1
  end
  array=option.split(",")
  index=index.to_i
  already=0

  if array[0]=="SENDMSG"

    for seqNumber in 0 .. counter-1
      str="CIRFRAG #{circuitID} #{index+1} #{destNode} #{seqNumber} #{counter} #{arry[seqNumber]} "
      nnode=circuit_nextHop(index,circuitID.to_i)
      $node_soc[nnode].puts(str)
    end


  else array[0]=="FTP"

      sendtime=$time
      fileSize=array[1].to_f
      filePath=array[2]
      fileName=array[3]

    begin
      for seqNumber in 0..counter-1
        str="CIRFRAG #{circuitID} #{index+1} #{destNode} #{seqNumber} #{counter} #{arry[seqNumber]}"
        nnode=circuit_nextHop(index,circuitID.to_i)
        $node_soc[nnode].puts(str)
        already=already+1
        sleep(0.001)
      end
      time=($time-sendtime).to_f
      speed=fileSize/time
      speed=speed.floor
      str= "#{fileName} --> #{destNode} in #{time}s at #{speed}bytes/s"
      STDOUT.puts (str)

    rescue
      if already!=counter
        nnode=circuit_nextHop(index,circuitID.to_i)
        fullPath="#{filePath}/#{fileName}"
        str="CIRFTPINTERUPT #{circuitID} 1 #{filePath}"
        dst=$circuitTalbe[circuitID].getDest()
        $node_soc[nnode].puts(str)
        transmitted=already * $maxPayload
        STDOUT.puts "FTP ERROR: #{fileName} --> #{dst} INTERRUPTED AFTER #{transmitted} bytes"
      end

    end
  end
end

def fragmentation_circuitm_server(args)
    circuitID=args[0].to_i
    index=args[1].to_i
    destNode=args[2]
    seqNumber=args[3]
    counter=args[4]
    message=args[5..-1]
    message=message.join(" ")
    nextNode=circuit_nextHop(index,circuitID)


    if $hostname ==destNode
      if !$circuitfragTable.has_key?(circuitID)
        $circuitfragTable[circuitID]=Hash.new
      end
      combination_circuitm(circuitID,seqNumber,counter,message)
      return
    end

    if nextNode != nil
      index=index.to_i
      index=index+1
      str="CIRFRAG #{circuitID} #{index} #{destNode} #{seqNumber} #{counter} #{message}"

      $node_soc[nextNode].puts(str)

    else
      if !$circuitfragTable.has_key?(circuitID)
          $circuitfragTable[circuitID]=Hash.new
      end
      combination_circuitm(circuitID,seqNumber,counter,message)
    end
end

def combination_circuitm(circuitID,seqNumber,total,message)
    circuitID=circuitID.to_i
    $circuitfragTable[circuitID][seqNumber]=message
    array=$circuitfragTable[circuitID].keys
    str=""
    $indicator=1

    if array.size == total.to_i
      index=total.to_i
      for i in 0..index-1
        m=i.to_s
        str<< $circuitfragTable[circuitID][m]
      end

      narray=str.split("+")

      if narray[0]=="SENDMSG"
        source=$circuitTalbe[circuitID].getSource()
        msg=narray[1..-1]
        msg=msg.join(" ")
        STDOUT.puts "CIRCUIT [#{circuitID}]/SENDMSG: [#{source}] --> [#{msg}]"
        $circuitfragTable.delete(circuitID)

      else
         temp=$circuitTalbe[circuitID]
         source=temp.getSource()
         fileName=narray[2]
         filePath=narray[3]
         currTime=narray[4]
         content=narray[5]
         begin

         content=content.gsub("(NEWLINE)","\n")
         content=content.gsub("(SPACE)","\s")
         content=content.gsub("(TAB)","\t")

         fullPath="#{filePath}/#{fileName}"


         if Dir.exists?(filePath)
         else
           Dir.mkdir (filePath)
         end
         Dir.chdir(filePath)

         File.open(fileName, 'w+b') do |file|
           file.write(content)
         end
         STDOUT.puts " CIRCUIT [#{circuitID}]/FTP [#{fileName}]: #{source} --> #{fullPath}"
         $indicator=0
         $fragTable.delete(source)

         rescue
           if $indicator!=0
             STDOUT.puts "CIRCUIT [#{circuitID}]/FTP ERROR: #{source} --> #{fullPath}"
           end
        end
        
      end
      $indicator=1

    end

end

def ping_circuitm(circuitID,information)
  circuitID=circuitID.to_i
  array=information.split(" ")
  numPing=array[0].to_i
  delay=array[1]
  destNode=array[2]
  nextNode=circuit_nextHop(0,circuitID)

  for seqNumber in 0..numPing-1
    sendTime=$time
    str="CIRPINGREQ #{seqNumber} 1 #{circuitID} #{sendTime} #{destNode}"
    $node_soc[nextNode].puts(str)

    $pingTable[seqNumber.to_i]=$time.to_f

    sleep(delay.to_i)
  end

end

def ping_server_circuitm(cmd)
  seqNumber= cmd[0]
  index=cmd[1].to_i
  circuitID=cmd[2]
  sendTime=cmd[3]
  destNode=cmd[4]


  nextNode=circuit_nextHop(index,circuitID)

  if nextNode==nil || $hostname==destNode
    prevNode=circuit_prevHop(index,circuitID)
    str="CIRPINGACK #{seqNumber} #{index-1} #{circuitID} #{sendTime} #{destNode}"
    $node_soc[prevNode].puts(str)
  else
    index=index+1
    str="CIRPINGREQ #{seqNumber} #{index} #{circuitID} #{sendTime} #{destNode}"
    $node_soc[nextNode].puts(str)
  end

end

def ping_ack_server_circuitm(cmd)
  seqNumber=cmd[0]
  index=cmd[1].to_i
  circuitID=cmd[2].to_i
  sendTime=cmd[3].to_f
  destNode=cmd[4]

  prevNode=circuit_prevHop(index,circuitID)

  if prevNode==nil
    rtt=$time.to_f-sendTime.to_f

    if $pingTable.has_key?(seqNumber.to_i)
      outStr="#{seqNumber} #{destNode} #{rtt} s"
      STDOUT.puts (outStr)
      $pingTable.delete(seqNumber.to_i)
    else

    end

  else
    index=index-1
    str="CIRPINGACK #{seqNumber} #{index} #{circuitID} #{sendTime} #{destNode}"
    $node_soc[prevNode].puts(str)
  end

end

def traceroute_circuitm(circuitID,information)
    circuitID=circuitID.to_i
    nextNode=circuit_nextHop(0,circuitID)
    sendTime=$time
    destNode=information

    str="CIRTRACEROUTEREQ #{circuitID} 0 1 #{sendTime} #{destNode}"
    $node_soc[nextNode].puts(str)

    STDOUT.puts "0 #{$hostname} 0ms"

end

def traceroute_server_circuitm(cmd)

  circuitID=cmd[0].to_i
  hops=cmd[1].to_i
  index=cmd[2].to_i
  sendTime=cmd[3].to_f
  destNode=cmd[4]


  nextNode=circuit_nextHop(index,circuitID)
  prevNode=circuit_prevHop(index,circuitID)

  if $hostname==destNode
    if prevNode !=nil && nextNode!=nil
      str="CIRTRACEROUTEACK #{circuitID} #{hops+1} #{index-1} #{sendTime}"
      $node_soc[prevNode].puts(str)
    else
      str="CIRTRACEROUTEACK #{circuitID} #{hops+1} #{index-1} #{sendTime}"
      $node_soc[prevNode].puts(str)
    end

  else
    if nextNode==nil
      str="CIRTRACEROUTEACK #{circuitID} #{hops+1} #{index-1} #{sendTime}"
      prevNode=circuit_prevHop(index,circuitID)
      $node_soc[prevNode].puts(str)
      return
    else
      str="CIRTRACEROUTEREQ #{circuitID} #{hops+1} #{index+1} #{sendTime} #{destNode}"
      $node_soc[nextNode].puts(str)
    end

    if prevNode !=nil && nextNode!=nil
      str="CIRTRACEROUTEACK #{circuitID} #{hops+1} #{index-1} #{sendTime}"
      $node_soc[prevNode].puts(str)
    end

  end

end

def traceroute_ack_server_circuitm(cmd)
  circuitID=cmd[0].to_i
  hops=cmd[1].to_i
  index=cmd[2].to_i
  sendTime=cmd[3].to_f
  prevNode=circuit_prevHop(index,circuitID)

  if index==0
    duration=$time-sendTime

    if duration > $pingTimeout
      str="TRACEROUTE TIMEOUT on #{hops}"
      STDOUT.puts(str)
    else
      duration=duration*1000
      temp=$circuitTalbe[circuitID]
      circuit=temp.instance_variable_get(:@circuit)
      array=circuit.split(",")
      str="#{hops} #{array[hops]} #{duration}ms"
      STDOUT.puts(str)
    end


  else
    str="CIRTRACEROUTEACK #{circuitID} #{hops} #{index-1} #{sendTime}"

    $node_soc[prevNode].puts(str)
  end

end

def ftpinteruptHandler_circuitm(cmd)
  circuitID=cmd[0].to_i
  index=cmd[1].to_i
  filPath=cmd[2]
  temp=$circuitTalbe[circuitID.to_i]
  source=temp.getSource()
  nnode=circuit_nextHop(index,circuitID)

  if nnode==nil
    $circuitfragTable.delete(circuitID)
    STDOUT.puts "FTP ERROR: #{source} --> #{filPath}"
  else
    str="CIRFTPINTERUPT #{circuitID} #{index+1} #{filePath}"
    $node_soc[nnode].puts(str)
  end
end




