def Dijkstra(native)
  #STDOUT.puts "--------Dijstra--------------------"
  #build and initialize the distance map
  distance_map={}
  pre_node={}
  q = Pqueue.new()
  distance_map[native]=0
  pre_node[native]=native
  q.push(native,0)

  costMap = $local_route[native].instance_variable_get(:@costMap)
  costMap.each do |key,value|
    distance_map[key]= $maxNum
    pre_node[key]='UNDEFINED'
    q.push(key,distance_map[key])
  end

  until q.isEmpty()
    u, distance_u=q.pop()
    u_costmap=$local_route[u].instance_variable_get(:@costMap)
    u_neighbours = $local_route[u].instance_variable_get(:@neighbours)
    if u_neighbours == nil
      next
    else
      u_neighbours.each do |v|
        if $destroy.include?(v)
          u_costmap[v]=$maxNum
        elsif u_costmap[v]==nil
          next
        else
          alt = distance_map[u].to_i + u_costmap[v].to_i
          if alt < distance_map[v].to_i
            distance_map[v]=alt
            pre_node[v]=u
            q.push(v,alt)
          end
        end
      end
    end
  end

  distance_map.delete(native)
  pre_node.delete(native)
  $local_route[native].putcostMap(distance_map)
  $local_route[native].putnextHopMap(pre_node)
end

def packet_to_str(flood_packet)
  costMap=flood_packet.instance_variable_get(:@costMap)
  nextHopMap=flood_packet.instance_variable_get(:@nextHopMap)
  neighbours=flood_packet.instance_variable_get(:@neighbours)
  if costMap==nil || nextHopMap == nil || neighbours==nil
    return nil
  end
  str = ""
  str<<flood_packet.instance_variable_get(:@source)
  str<<";"
  str<<flood_packet.instance_variable_get(:@sequenceNumber).to_s
  costMap.each do |key,value|
    str<<";"
    str<<key
    str<<","
    if(nextHopMap[key]==nil)
      str<< "unknown"
    else
      str<< nextHopMap[key]
    end
    str<<","
    if(nextHopMap[key]==nil)
      str<< $maxNum.to_s
    else
      str<< costMap[key].to_s
    end
  end
  str<<'/'
  neighbours.each do |key|
    str<<key
    str<<","
  end
  return str
end

def str_to_packet(flood_str)
  array = flood_str.split('/')
  arr = array[0].split(';')
  neighbours = array[1].split(',')
  source = arr[0]
  sequenceNumber = arr[1].to_i+1
  costmap = {}
  hopmap = {}
  for i in 2..arr.length-1
    node_info=arr[i].split(',')
    costmap[node_info[0]]=node_info[2]
    hopmap[node_info[0]] =node_info[1]
  end
  flood_packet=CostPackage.new(source, costmap, hopmap, sequenceNumber)
  flood_packet.updateNeighbours(neighbours)
  return flood_packet
end

def flooding(flood_packet)
  # packet to str
  flood_str = packet_to_str(flood_packet)
  if flood_str == nil # if packet is empty, we will not flood it
    #STDOUT.puts "flood packet is empty"
    return
  end
  $node_soc.each do|key,value|
    if key!=flood_packet.instance_variable_get(:@source) && key!=$hostname
      line="FLOODING #{flood_str}"
      $node_soc[key].puts(line)
      #STDOUT.puts "---flood packet "<< "[source] "<<flood_packet.instance_variable_get(:@source)<< " [to] "<< key
    else
      #STDOUT.puts "---not flood packet "<< "[source] "<<flood_packet.instance_variable_get(:@source)<< " [to] "<< key
    end
  end
end


def update()
  # Flooding
  flood_packet = $local_route[$hostname]
  neighbours=[]
  $node_soc.each do |key, value|
    neighbours.push(key)
  end
  flood_packet.updateNeighbours(neighbours)
  flooding(flood_packet)
  # # Dijstra
  Dijkstra($hostname)
end


# --------------------- Part 1 --------------------- #
def edged(cmd)
  dst = cmd[0]
  costmap=$local_route[$hostname].instance_variable_get(:@costMap)
  nextHopMap=$local_route[$hostname].instance_variable_get(:@costMap)
  costmap[dst]=$maxNum
  nextHopMap[dst]=nil
  $local_route[$hostname].putcostMap(costmap)
  $local_route[$hostname].putnextHopMap(nextHopMap)
  $destroy<<dst

end

def edgeu(cmd)
  # puts "EDGEU"
  if cmd.length >2
    # puts "wrong number of arguments"
    return
  end
  dstNode=cmd[0]
  cost=cmd[1]
  if cost.to_i > $maxNum
    STDOUT.puts "exceed max number"
    return
  end
  if $node_soc.has_key?(dstNode)
    if $destroy.include?(dstNode)
      return
    else
      costmap=$local_route[$hostname].instance_variable_get(:@costMap)
      costmap[dstNode]=cost
      $local_route[$hostname].putcostMap(costmap)
    end
  end
end

def status()
  str= 'Name: '
  str<<$hostname
  str<<' Port: '
  str<<$node_port[$hostname]
  str<<' Neighbors: '
  neighbour=[]
  $node_soc.each do |key, value|
    if $destroy.include?(key)
      next
    end
    neighbour.push(key)
  end
  neighbour.sort!
  for i in 0..neighbour.length-1
    str<<neighbour[i]
    if i != neighbour.length-1
      str<<','
    end
  end
  STDOUT.puts str
end