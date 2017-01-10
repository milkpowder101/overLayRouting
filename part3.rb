# --------------------- Part 3 --------------------- #
require_relative 'circuitTable'
require_relative 'circuitmsubfile'

$circuitTalbe=Hash.new


# from one end to another end,the middle path only pass to the destination.

def circuitb(cmd)
    circuitID=cmd[0].to_i
    destNode=cmd[1]
    information=cmd[2]
    if information.length==0
      STDOUT.puts "no circuit input"
      return
    end
    array=information.split(",")
    nextNode=array[0]
    if !$node_soc.has_key?(nextNode)
      STDOUT.puts "CIRCUIT ERROR: [#{$hostname}] -/-> [#{destNode}] FAILED AT [#{nextNode}]"
      return
    end
    if $circuitTalbe.has_key?(circuitID.to_i)
      STDOUT.puts "Circuit ID already build"
      return
    end
    array<<destNode
    array.insert(0,$hostname)
    cirCuit=array[0..-1].join(",")
    str="CIRCUITB #{circuitID} #{$hostname} #{destNode} #{cirCuit} 1"
    $node_soc[nextNode].puts(str)
end

def circuitb_server(cmd)

  #to handle CIRCUITB

  # puts "circuitb_server #{cmd}"

    circuitID=cmd[1].to_i
    source=cmd[2]
    destNode=cmd[3]
    circuit=cmd[4]
    index=cmd[5].to_i
    index=index+1
    array=circuit.split(",")
    nnode=array[index]

  if destNode==$hostname && nnode == nil
    temp=CircuitTable.new(circuitID.to_i,source,destNode,circuit,1)
    $circuitTalbe[circuitID.to_i]=temp
    # puts $circuitTalbe
    index=index-1
    index=index-1
    array=circuit.split(",")
    nextNode=array[index]
    hops=array.length-2
    STDOUT.puts "CIRCUIT [#{source}]/[#{circuitID}] --> [#{destNode}] over [#{hops}]"

    str="CIRCUITBACK #{circuitID.to_i} #{source} #{destNode} #{circuit} #{index}"
    $node_soc[nextNode].puts(str)

  else
    if $node_soc.has_key?(nnode)
      str="CIRCUITB #{circuitID} #{source} #{destNode} #{circuit} #{index}"
      $node_soc[nnode].puts(str)

    else
      str="CIRCUITBFAIL #{circuitID} #{source} #{destNode} #{nnode}"
      nextNode=nextHop(source)
      $node_soc[nextNode].puts(str)
    end
  end
end

def circuitb_ack_server(cmd)
    # puts "circuit ack server #{cmd}"
    circuitID=cmd[0].to_i
    source=cmd[1]
    destNode=cmd[2]
    circuit=cmd[3]
    index=cmd[4].to_i
    index=index-1

    if source==$hostname
      temp=CircuitTable.new(circuitID,source,destNode,circuit,1)
      $circuitTalbe[circuitID.to_i]=temp
      hops=circuit.split(",")
      hops=hops.size
      hops=hops-2

      STDOUT.puts "CIRCUITB [#{circuitID}] --> [#{destNode}] over [#{hops}]"

      return
    end

    if  $circuitTalbe.has_key?(circuitID)
      temp=$circuitTalbe[circuitID]
      x=temp.getTime()
      x=x.to_i
      x=x+1
      temp.setTime(x)
      $circuitTalbe[circuitID]=temp
    else
      temp=CircuitTable.new(circuitID.to_i,source,destNode,circuit,1)
      $circuitTalbe[circuitID.to_i]=temp
    end

    array=circuit.split(",")
    nextNode=array[index]
    str="CIRCUITBACK #{circuitID.to_i} #{source} #{destNode} #{circuit} #{index}"
    $node_soc[nextNode].puts(str)

    # puts $circuitTalbe
end

def circuitb_fail_server(cmd) #CIRCUITBFAIL
  circuitID=cmd[1].to_i
  source=cmd[2]
  destNode=cmd[3]
  failNode=cmd[4]
  if source==$hostname
    STDOUT.puts "CIRCUIT ERROR: [#{source}] -/-> [#{destNode}] FAILED AT [#{failNode}]"
  else
    nextnode=nextHop(source)
    str="CIRCUITBFAIL #{circuitID} #{source} #{destNode} #{failNode}"
    $node_soc[nextnode].puts(str)
  end
end



def circuitd(cmd)
    circuitID=cmd[0].to_i
    
    if $circuitTalbe.has_key?(circuitID)
        circuit =$circuitTalbe[circuitID].instance_variable_get(:@circuit)
        source  =$circuitTalbe[circuitID].instance_variable_get(:@sourceNode)
        dst     =$circuitTalbe[circuitID].instance_variable_get(:@destNode)
        array   =circuit.split(',')
        nextnode =array[1]
        
        if $node_soc.has_key?(nextnode) #try to send delete
            str="CIRCUIT_to_delete #{circuitID} #{circuit} 1"
            $node_soc[nextnode].puts(str)
            else
            str ="CIRCUITD ERROR: #{source} --> #{dst} FAILED AT #{nextnode}"
            STDOUT.puts str
        end
        else
        STDOUT.puts "CIRCUITD ERROR: #{source} --> #{dst} FAILED AT #{$hostname}"
    end
end

def circuit_to_delete(cmd)
    circuitID =cmd[0]
    circuit =cmd[1]
    index =cmd[2].to_i
    
    array =circuit.split(",")
    source =array[0]
    nextnode =array[index+1]
    dst =array[-1]
    
    
    if $circuitTalbe.has_key?(circuitID.to_i)
        if dst ==$hostname # delete packet arrive at dst
            $circuitTalbe.delete(circuitID.to_i)
            str ="CIRCUITD_ACK #{circuitID.to_i} #{source} #{dst}"
            nextNode=nextHop(source)
            $node_soc[nextNode].puts(str)
            else # delete packet have not arrive at dst yet
            times =$circuitTalbe[circuitID.to_i].getTime()
            times =times.to_i
            times =times-1
            if times ==0
#                puts "times:"<<times.to_s<<"delete"
                $circuitTalbe.delete(circuitID.to_i)
                str ="CIRCUIT_to_delete #{circuitID} #{circuit} #{index.to_i+1}"
                #$node_soc[nextnode].puts(str)
                if !$destroy.include?(nextnode)
                    $node_soc[nextnode].puts(str)
                    else
                    str ="CIRCUITD_fail_ack #{circuitID} #{source} #{dst} #{nextnode}"
                    nextNode=nextHop(source)
                    $node_soc[nextNode].puts(str)
                end
                ###########
                else
#                puts "times:"<<times.to_s<<"minus one"
                $circuitTalbe[circuitID.to_i].setTime(times)
                str ="CIRCUIT_to_delete #{circuitID} #{circuit} #{index.to_i+1}"
                #$node_soc[nextnode].puts(str) #need to see if connection break
                if !$destroy.include?(nextnode) #try to send delete
                    $node_soc[nextnode].puts(str)
                    else
                    str ="CIRCUITD_fail_ack #{circuitID} #{source} #{dst} #{nextnode}"
                    nextNode=nextHop(source)
                    $node_soc[nextNode].puts(str)
                end
                ###########
            end
        end
        else
        str ="CIRCUITD_fail_ack #{circuitID} #{source} #{destNode} #{nextnode}"
        nextNode=nextHop(source)
        $node_soc[nextNode].puts(str)
    end
end

def circuitd_ack_server(cmd)
    circuitID =cmd[0].to_i
    source =cmd[1]
    destNode =cmd[2]
    
    if source==$hostname
        circuit =$circuitTalbe[circuitID.to_i].instance_variable_get(:@circuit)
        hops =circuit.split(",")
        hops =hops.size
        hops =hops-2
        str ="CIRCUITD #{circuitID} --> #{destNode} over #{hops}"
        STDOUT.puts str
        $circuitTalbe.delete(circuitID.to_i)
        else
        str ="CIRCUITD_ACK #{circuitID.to_i} #{source} #{destNode}"
        nextNode=nextHop(source)
        $node_soc[nextNode].puts(str)
    end
end

def circuitd_fail_server(cmd)
    circuitID =cmd[0].to_i
    source =cmd[1]
    destNode =cmd[2]
    failNode =cmd[3]
    
    if source==$hostname
        STDOUT.puts "CIRCUITD ERROR: #{source} --> #{destNode} FAILED AT #{failNode}"
        else
        str ="CIRCUITD_fail_ack #{circuitID} #{source} #{destNode} #{failNode}"
        nextNode=nextHop(source)
        $node_soc[nextNode].puts(str)
    end
end

