# --------------------- Part 0 --------------------- #

class CostPackage  #class of link state package
  attr_accessor :sequenceNumber, :costMap,:status,:nextHopMap   #enable changing to sequenceNumber and costMap
  @source
  @status
  @sequenceNumber# int
  @costMap={}
  @nextHopMap={}
  @neighbours=[]
  def initialize(source, costmap, hopmap, sequenceNumber)
    @source=source
    @sequenceNumber = sequenceNumber
    @status = false
    @costMap=costmap
    @nextHopMap=hopmap
  end
  def putcostMap(map)   #function to copy cost map into class
    @costMap=map
  end
  def putnextHopMap(map) #function to copy next hop map into class
    @nextHopMap=map
  end
  def seeMap()    #function to see the elements of map
    keys = @costMap.keys;
    for i in 0..keys.length-1
      puts keys[i]+ ":"+ @costMap[keys[i]];
    end
  end
  def map()
    return @costMap
  end
  def updateNeighbours(array)
    @neighbours=array
  end
end

def edgebreq(arr)
  fromNode=arr[1]
  fromIP=arr[2]
  fromPort=arr[3]
  if $node_soc.has_key?(fromNode)
    return
  end

  begin
    s=TCPSocket.open(fromIP,fromPort)
    if s

      if $local_route[$hostname].instance_variable_get(:@costMap)==nil || $local_route[$hostname].instance_variable_get(:@nextHopMap)==nil
        costmap=Hash.new
        costmap[fromNode]=1
        hostmap=Hash.new
        hostmap[fromNode]=fromNode
      else
        costmap=$local_route[$hostname].instance_variable_get(:@costMap)
        costmap[fromNode]=1
        hostmap=$local_route[$hostname].instance_variable_get(:@nextHopMap)
        hostmap[fromNode]=fromNode
      end

      $local_route[$hostname].putcostMap(costmap)
      $local_route[$hostname].putnextHopMap(hostmap)

      $node_soc[fromNode]=s
    end
  rescue
    STDOUT.puts "EDGEBREQ something wrong"
  end
end

def edgeb(cmd)
  if cmd.size >3
    STDOUT.puts("ERROR : wrong number of arguments")
    return
  end
  localIP=cmd[0]
  destIP=cmd[1]
  destNode=cmd[2]
  # the node can not connect to it self. Prevent this happen.
  if destNode == $hostname
    return
  end
  # check duplication.
  if $destroy.include?(destNode)
    $destroy.delete_at($destroy.find_index(destNode))
  end

  # check duplication.
  if $node_soc.has_key?(destNode)
    costmap=$local_route[$hostname].instance_variable_get(:@costMap)
    costmap[destNode]=1
    hostmap=$local_route[$hostname].instance_variable_get(:@nextHopMap)
    hostmap[destNode]=destNode
    $local_route[$hostname].putcostMap(costmap)
    $local_route[$hostname].putnextHopMap(hostmap)
    return
  end


  begin
    s=TCPSocket.open(destIP,$node_port[destNode])
    if s
      s.puts("EDGEBREQ #{$hostname} #{localIP} #{$port}")
      if $local_route[$hostname].instance_variable_get(:@costMap)==nil || $local_route[$hostname].instance_variable_get(:@nextHopMap)==nil
        costmap=Hash.new
        costmap[destNode]=1
        hostmap=Hash.new
        hostmap[destNode]=destNode
      else
        costmap=$local_route[$hostname].instance_variable_get(:@costMap)
        costmap[destNode]=1
        hostmap=$local_route[$hostname].instance_variable_get(:@nextHopMap)
        hostmap[destNode]=destNode
      end

      $local_route[$hostname].putcostMap(costmap)
      $local_route[$hostname].putnextHopMap(hostmap)
      $node_soc[destNode]=s
    end
  rescue
    STDOUT.puts "EDGEB function, something wrong."
  end
end
# def dumptable(cmd)
#   txt=File.open(cmd[0],"w+")
#   $local_route.each do |node, packet|
#     costMap=packet.instance_variable_get(:@costMap)
#     nextHopMap=packet.instance_variable_get(:@nextHopMap)
#     if costMap==nil || nextHopMap == nil
#       STDOUT.puts"nothing in table, cant dump"
#       return
#     end
#     costMap.each do |key,value|
#       str= ''
#       str<<node
#       str<<","
#       str<<key
#       str<<","
#       if(nextHopMap[key]==nil)
#         str<< "unknown"
#       else
#         str<< nextHopMap[key]
#       end
#
#       str<<","
#       if(nextHopMap[key]==nil || nextHopMap[key]==$maxNum)
#         str<< "infinity"
#       else
#         str<< costMap[key].to_s
#       end
#       str<<	"\n"
#       txt.print(str)
#     end
#
#   end
#   txt.close
# end

def dumptable(cmd)
  txt=File.open(cmd[0],"w+")
  $local_route.each do |node, packet|
    costMap=packet.instance_variable_get(:@costMap)
    nextHopMap=packet.instance_variable_get(:@nextHopMap)

    if node!=$hostname
      next
    end

    if costMap==nil || nextHopMap == nil
      STDOUT.puts"nothing in table, cant dump"
      return
    end
    costMap.each do |key,value|
      str= ''
      str<<node
      str<<","
      str<<key
      str<<","
      if(nextHopMap[key]==nil || nextHopMap[key]=="unknown" || nextHopMap[key]=="UNDEFINED")
        str<< "unknown"
      else
        routeTalbePrev=$local_route[node].instance_variable_get(:@nextHopMap)
        neighbourTalbe=$local_route[node].instance_variable_get(:@neighbours)
        queue=Queue.new

        if routeTalbePrev[key] == node
          str<< key.to_s
        elsif neighbourTalbe.include?(routeTalbePrev[key])
          str<< routeTalbePrev[key].to_s
        else
          queue.push(routeTalbePrev[key])
          until queue.empty?()
            cnode=queue.pop()
            if neighbourTalbe.include?(cnode)
              str<<cnode.to_s
              break
            else
              queue.push(routeTalbePrev[cnode])
            end
          end
        end
      end


    str<<","
    if(nextHopMap[key]==nil)
        str<< "infinity"
    else
      if costMap[key] == $maxNum || costMap[key] == $maxNum.to_s
        str<< "infinity"
     else
        str<< costMap[key].to_s
      end

    end


      str<<	"\n"
      txt.print(str)
    end

  end
  txt.close
end



# def dumptable(cmd)
# 	txt=File.open(cmd[0],"w+")
# 	costMap=$local_route[$hostname].instance_variable_get(:@costMap)
# 	nextHopMap=$local_route[$hostname].instance_variable_get(:@nextHopMap)
# 	if costMap==nil || nextHopMap == nil
# 		STDOUT.puts"nothing in table, cant dump"
# 		return
# 	end
# 	costMap.each do |key,value|
# 		str= ''
# 		str<<$hostname
# 		str<<","
# 		str<<key
# 		str<<","
# 		if(nextHopMap[key]==nil)
# 			str<< "unknown"
# 		else
# 			str<< nextHopMap[key]
# 		end
# 		str<<","
# 		if(nextHopMap[key]==nil)
# 			str<< "infinity"
# 		else
# 			str<< costMap[key].to_s
# 		end
# 		str<<	"\n"
# 		txt.print(str)

# 	end
# 	txt.close
# end

def shutdown(cmd)
  $node_soc.each do|key,value|
    line="SHUTDOWNFROM #{$hostname}"
    $node_soc[key].puts(line)
  end

  Thread.list.each do |thread|
    thread.kill unless thread == Thread.current
  end
  exit(0)
end
