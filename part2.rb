# --------------------- Part 2 --------------------- #
$fragTable=Hash.new
$pingTable=Hash.new


def nextHop(destNode)
  routeTable=$local_route[$hostname].instance_variable_get(:@costMap)
  routeTalbePrev=$local_route[$hostname].instance_variable_get(:@nextHopMap)
  queue=Queue.new
  queue.push(destNode)
  if $node_soc.has_key?(destNode)
    return destNode
  end
  until queue.empty?()
    node=queue.pop()
    if $node_soc.has_key?(routeTalbePrev[node])
      return routeTalbePrev[node]
    else
      queue.push(routeTalbePrev[node])
    end
  end
end

def pingchecker()
  loop{
    if $pingTable.keys.length !=0
      m=$pingTable.sort()
      m=m.shift()
      firstElement=m.shift()
      if $pingTable.has_key?(firstElement.to_i)

        if ($pingTable[firstElement.to_i].to_f - $time.to_f).abs >= $pingTimeout.to_f
          STDOUT.puts("PING ERROR: HOST UNREACHABLE")
          $pingTable.delete(firstElement.to_i)
        end

      end

    end
    sleep(0.00001)
  }

end


def ping(cmd)
  destNode=cmd[0]
  numPing=cmd[1].to_i
  delay=cmd[2].to_i
  source=$hostname
  routeTable=$local_route[$hostname].instance_variable_get(:@costMap)
  routeTalbePrev=$local_route[$hostname].instance_variable_get(:@nextHopMap)


  if routeTable[destNode].to_i==$maxNum || routeTable[destNode].to_i==nil
    STDOUT.puts "PING ERROR: HOST UNREACHABLE"
    return
  elsif !routeTable.has_key?(destNode)
    STDOUT.puts "PING ERROR: HOST UNREACHABLE"
    return
  end
  # if destination is source then = 0ms
  if destNode==source
    for i in 0..numPing-1
      STDOUT.puts "#{i} #{source} 0ms"
      sleep(delay.to_i)
    end
    return
  end

    for seqNumber in 0..numPing-1
      sendTime=$time
      nextNode=nextHop(destNode)
      str="PINGREQ #{seqNumber} #{source} #{destNode} #{sendTime}"
      #STDOUT.puts(str)
      $node_soc[nextNode].puts(str)

      $pingTable[seqNumber.to_i]=$time.to_f

      sleep(delay.to_i)
    end

end

def ping_server(cmd)
  # puts "ping_server"
  # puts cmd
  seqNumber= cmd[0]
  sourceNode=cmd[1]
  destNode=cmd[2]
  time=cmd[3].to_f

  if destNode == $hostname
    ctime=$time.to_f
    nnode=nextHop(sourceNode)
    ttime=$time.to_f
    time=time+(ttime-ctime)
    str="PINGACK #{seqNumber} #{sourceNode} #{destNode} #{time}"
    $node_soc[nnode].puts(str)
  else
    ctime=$time.to_f
    nnode=nextHop(destNode)
    ttime=$time.to_f
    time=time+(ttime-ctime)

    str="PINGREQ #{seqNumber} #{sourceNode} #{destNode} #{time}"
    $node_soc[nnode].puts(str)
  end

end

def ping_ack_server(cmd)
  # puts "ping_ack_server"
  # puts cmd
  seqNumber=cmd[0]
  sourceNode=cmd[1]
  destNode=cmd[2]
  time=cmd[3].to_f

  if sourceNode==$hostname
    rtt=$time.to_f-time.to_f
    if $pingTable.has_key?(seqNumber.to_i)
      outStr="#{seqNumber} #{destNode} #{rtt} s"
      STDOUT.puts (outStr)
      $pingTable.delete(seqNumber.to_i)

    end

  else
    ctime=$time
    nnode=nextHop(sourceNode)
    ttime=$time
    time=time+(ttime-ctime).abs
    str="PINGACK #{seqNumber} #{sourceNode} #{destNode} #{time}"
    $node_soc[nnode].puts(str)
  end


end

def traceroute(cmd)
  destNode=cmd[0]
  source=$hostname
  time=$time
  routeTable=$local_route[$hostname].instance_variable_get(:@costMap)
  routeTalbePrev=$local_route[$hostname].instance_variable_get(:@nextHopMap)

  if routeTable[destNode] == "infinity" || routeTable[destNode].to_i==$maxNum
    STDOUT.puts "TRACEROUTE ERROR: HOST UNREACHABLE"
    return
  elsif !routeTable.has_key?(destNode)
    STDOUT.puts "TRACEROUTE ERROR: HOST UNREACHABLE"
    return
  end

  strr="0 #{$hostname} 0 ms"
  STDOUT.puts(strr)
  str="TRACEROUTE #{source} #{destNode} #{time} 0"
  nnode=nextHop(destNode)
  $node_soc[nnode].puts(str)
end

def traceroute_server(cmd)
  # puts "traceroute_server #{cmd}"
  source=cmd[0]
  destNode=cmd[1]
  time=cmd[2].to_f
  numHop=cmd[3].to_i

  if destNode!=$hostname
    plusone=numHop.to_i+1
    str="TRACEROUTE #{source} #{destNode} #{time} #{plusone}"
    nnode=nextHop(destNode)
    $node_soc[nnode].puts(str)

    strr="TRACEROUTEACK #{source} #{$hostname} #{time} #{plusone}"
    pnode=nextHop(source)
    $node_soc[pnode].puts(strr)
  else
    plusone=numHop.to_i+1
    strr="TRACEROUTEACK #{source} #{destNode} #{time} #{plusone}"
    pnode=nextHop(source)
    $node_soc[pnode].puts(strr)
  end
end

def traceroute_server_ack(cmd)
  # puts "traceroute_server_ack #{cmd}"
  source=cmd[0]
  destNode=cmd[1]
  time=cmd[2].to_f
  numHop=cmd[3].to_i
  currentTime=$time.to_f

  if source!=$hostname
    strr="TRACEROUTEACK #{source} #{destNode} #{time} #{numHop}"
    pnode=nextHop(source)
    $node_soc[pnode].puts(strr)
  else
    time=(currentTime.to_f-time.to_f).abs
    if time > $pingTimeout
      str="TIMEOUT ON #{numHop}"
      STDOUT.puts str

    else
      time=time*1000
      str="#{numHop} #{destNode} #{time} ms"
      STDOUT.puts str
    end
  end
end

def sendmsgserver(cmd)
  source=cmd[0]
  destNode=cmd[1]
  message=cmd[2]
  if destNode ==$hostname
    message=message.split('@')
    message=message.join(' ')
    STDOUT.puts "SENDMSG: [#{source}] --> [#{message}]"
    return
  end
  str=""
  str<<"SENDMESSAGE"
  str<<" "
  str<<cmd.join(" ")
  routeTable=$local_route[$hostname].instance_variable_get(:@costMap)
  routeTalbePrev=$local_route[$hostname].instance_variable_get(:@nextHopMap)
  # if it's neighbour, send out
  if $node_soc.has_key?(destNode)
    $node_soc[destNode].puts(str)
    return
  end
  # if it is not neighbour, then need to find the prev node of destination.
  queue=Queue.new
  queue.push(destNode)
  until queue.empty?()
    node=queue.pop()
    if $node_soc.has_key?(routeTalbePrev[node])
      $node_soc[routeTalbePrev[node]].puts(str)
      break
    else
      queue.push(routeTalbePrev[node])
    end
  end

end

def fragmentation(message,maxSize,source,destination,option)
  counter=0
  arry=Array.new
  if message.length == 0
    return arry,counter
  end
  while message.length > 0
    x=message.slice!(0,maxSize)
    arry<<x
    counter=counter+1
  end
  array=option.split(",")
  if array[0]=="SENDMSG"
    for seqNumber in 0..counter-1
      str="FRAGMENT #{source} #{destination} #{seqNumber} #{counter} #{arry[seqNumber]}"
      # puts str
      nnode=nextHop(destination)
      $node_soc[nnode].puts(str)
    end

  elsif array[0]=="FTPMSG"
    begin
    sendtime=$time
    fileSize=array[1].to_f
    already=0
      for seqNumber in 0..counter-1
        str="FRAGMENT #{source} #{destination} #{seqNumber} #{counter} #{arry[seqNumber]}"

        # puts str

        nnode=nextHop(destination)
        $node_soc[nnode].puts(str)
        already=already+1
        sleep(0.001)
      end
    time=($time-sendtime).to_f
    speed=fileSize/time
    fileName=array[2]
    dst=array[3]
    filePath=array[4]
    speed=speed.floor

    STDOUT.puts "#{fileName} --> #{dst} in #{time}ms at #{speed}bytes/s"

    rescue

      nnode = nextHop(dst)
      fullPath="#{filePath}/#{fileName}"
      str="FTPINTERUPT #{$hostname} #{dst} #{filePath}"
      $node_soc[nnode].puts(str)
      STDOUT.puts "FTP ERROR: #{fileName} --> #{dst} INTERRUPTED AFTER #{already * $maxPackageSize} bytes"

    end

  end
end

def fragment_server(line)
  cmd=line.split(" ")
  command=cmd[0]
  source=cmd[1]
  destNode=cmd[2]
  crrID=cmd[3]
  total=cmd[4]
  line.slice!(0,command.length+source.length+destNode.length+crrID.length+total.length+5)
  message=line
  # puts line
  if destNode!=$hostname
    nnode=nextHop(destNode)
    str="FRAGMENT #{source} #{destNode} #{crrID} #{total} #{message}"
    $node_soc[nnode].puts(str)
  else
      if !$fragTable.has_key?(source)
          $fragTable[source]=Hash.new
      end
    combination(source,crrID,total,message)
  end
end

def combination(source,currID,total,message)
    $fragTable[source][currID]=message
    array=$fragTable[source].keys
    str=""

    if array.size == total.to_i
      index=total.to_i
      for i in 0..index-1
        m=i.to_s
        str<< $fragTable[source][m]
      end
    end

    if str.length !=0
      arr = str.split("+")

      if arr[0]=="SENDMESSAGE"
        source=arr[1]
        dest=arr[2]
        message=arr[3]
        message=message.split('@')
        message=message.join(' ')
        message=message.split("\n")
        message=message.join(' ')
        STDOUT.puts "SENDMSG: [#{source}] --> [#{message}]"
        $fragTable.delete(source)

      elsif arr[0]=="FTP"
          source=arr[1]
          dest=arr[2]
          fileName=arr[3]
          filePath=arr[4]
          senderTime=arr[5]
          fileSize=arr[6]
          # get back \n
          begin

            # str.slice!(0,arr[0].length+source.length+dest.length+fileName.length+filePath.length+senderTime.length+fileSize.length+7)
            # message=str
            message=arr[7].split("\n")
            message=message.join


          message=message.gsub("(NEWLINE)","\n")
          message=message.gsub("(SPACE)","\s")
          message=message.gsub("(TAB)","\t")


          fullPath="#{filePath}/#{fileName}"

          if Dir.exists?(filePath)
          else
            Dir.mkdir (filePath)
          end
          Dir.chdir(filePath)

          IO.binwrite(fileName,message)

          STDOUT.puts "FTP: #{source} --> #{fullPath}"
          $fragTable.delete(source)

          rescue
            STDOUT.puts "FTP ERROR: #{source} --> #{fullPath}"

          end
      end
    end


end

def sendmsg(cmd)
    destNode=cmd[0]
    message=cmd[1..-1]
    message=message.join("@")

    if message == nil
      return
    end
    if destNode==$hostname
      message.split("@")
      message.join(" ")
      STDOUT.puts "SENDMSG: [SRC#{destNode}] --> [#{message}]"
    end
    str="SENDMESSAGE #{$hostname} #{destNode} #{message}"
    routeTable=$local_route[$hostname].instance_variable_get(:@costMap)

    if routeTable[destNode] == "infinity" || routeTable[destNode].to_i >= $maxNum
      STDOUT.puts "SENDMSG ERROR: HOST UNREACHABLE"
      return
    elsif !routeTable.has_key?(destNode)
      STDOUT.puts "SENDMSG ERROR: HOST UNREACHABLE"
      return
    end


    if str.length > $maxPayload
      str="SENDMESSAGE+#{$hostname}+#{destNode}+#{message}"
      fragmentation(str,$maxPayload,$hostname,destNode,"SENDMSG")
      return
    else
      nnode=nextHop(destNode)
      $node_soc[nnode].puts(str)
    end

end

def ftp(cmd)
  destNode=cmd[0]
  fileName=cmd[1]
  filePath=cmd[2]
  routeTable=$local_route[$hostname].instance_variable_get(:@costMap)
  if routeTable[destNode].to_i >= $maxNum || routeTable[destNode].to_i==nil
    STDOUT.puts "FTP ERROR: HOST UNREACHABLE"
    return
  elsif !routeTable.has_key?(destNode)
    STDOUT.puts "FTP ERROR: HOST UNREACHABLE"
    return
  end
  if !File.exist?(fileName)
    STDOUT.puts "FILE DOESN'T EXIST"
    return
  end

  fileSize=File.size(fileName)
  currTime=$time


  contents = IO.binread(fileName)
  contents=contents.gsub("\n","(NEWLINE)")
  contents=contents.gsub("\s","(SPACE)")
  contents=contents.gsub("\t","(TAB)")



  str="FTP+#{$hostname}+#{destNode}+#{fileName}+#{filePath}+#{currTime}+#{fileSize}+#{contents}"

  fragmentation(str,$maxPayload,$hostname,destNode,"FTPMSG,#{fileSize},#{fileName},#{destNode},#{filePath}")

end

def ftpinteruptHandler(cmd)
  command=cmd[0]
  source=cmd[1]
  destnation=cmd[2]
  filePath=cmd[3]

  if destnation==$hostname
    $fragTable.delete(source)
    STDOUT.puts "FTP ERROR: #{source} --> #{filePath}"
  else
    nnode=nextHop(destnation)
    str=cmd.join(" ")
    $node_soc[nnode].puts(str)
  end

end



