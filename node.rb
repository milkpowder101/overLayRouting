require 'socket'
require 'io/console'
require 'timeout'
require 'time'
require 'thread'

require_relative 'pqueue'
require_relative 'part0'
require_relative 'part1'
require_relative 'part2'
require_relative 'part3'


#maximum integer is 2147483647
$maxNum=2147483647
# read from the config file
$updateInterval
$maxPayload
$pingTimeout
$time

$port = nil
$hostname = nil
$local_route={} # used to store, node to costPackage class
$sock_array=[] 	# this array is only used for listening. So only listening thread push the socket
$node_soc={} 		# used to send thing
$node_port={} 	# initialization, remember the node to port map
$destroy=[]

def clock()
	loop{
		sleep(0.000001)
		$time=$time+0.000001
	}
end

def listening(port)
	server = TCPServer.open(port)
	loop {
		client =server.accept
		if client
			$sock_array.push(client)
		end
	}
end

def read(sockArray)
	loop{
		readable,writable,error = IO.select(sockArray,nil,nil,0.01)
		if readable !=nil
			readable.each do |socket|
				line=socket.gets()
				if  line !='' && line !=nil
					cmdhandler(line)
				end
			end
		end
	}
end

def cmdhandler(line)
	originalLine=line
	line = line.strip()
	# STDOUT.puts "----- #{line}"
	arr = line.split(' ')
	cmd = arr[0]
	case cmd
		when "EDGEBREQ";
			edgebreq(arr)
		when "SHUTDOWNFROM";
			fromNode=arr[1]
			$node_soc.delete(fromNode)
			$local_route.delete(fromNode)
		when "FLOODING";
			flood_packet = str_to_packet(arr[1])
			# to see if we need to flood this packet anymore
			# if we have
			source = flood_packet.instance_variable_get(:@source)
			sequenceNumber = flood_packet.instance_variable_get(:@sequenceNumber)
			costmap = flood_packet.instance_variable_get(:@costMap)
			nextHopMap = flood_packet.instance_variable_get(:@nextHopMap)
			neighbours = flood_packet.instance_variable_get(:@neighbours)
			#STDOUT.puts "flooding received from "<< source<< "; seq= "<<sequenceNumber.to_s
			if $local_route.has_key?(source)
				if sequenceNumber<=$local_route[source].instance_variable_get(:@sequenceNumber)
					$local_route[source].putcostMap(costmap)
					$local_route[source].putnextHopMap(nextHopMap)
					$local_route[source].updateNeighbours(neighbours)
					#STDOUT.puts "--------to flood"
					flooding(flood_packet)
				end
			else
				$local_route[source]=CostPackage.new(source, costmap, nextHopMap, sequenceNumber)
				$local_route[source].updateNeighbours(neighbours)
				#STDOUT.puts "--------to flood"
				flooding(flood_packet)
			end

		when "SENDMESSAGE";sendmsgserver(arr[1..-1])
		when "PINGREQ";ping_server(arr[1..-1])
		when "PINGACK";ping_ack_server(arr[1..-1])
		when "TRACEROUTE"; traceroute_server(arr[1..-1])
    when "TRACEROUTEACK";traceroute_server_ack(arr[1..-1])
		when "FRAGMENT"; fragment_server(originalLine)
		when "FTPINTERUPT"; ftpinteruptHandler(arr[0..-1])




		#circuit
		when "CIRCUITB"; circuitb_server(arr[0..-1])
		when "CIRCUITBFAIL"; circuitb_fail_server(arr[0..-1])
		when "CIRCUITBACK";circuitb_ack_server(arr[1..-1])
		#circumM
		when "CIRFRAG";fragmentation_circuitm_server(arr[1..-1])
		when "CIRPINGREQ";ping_server_circuitm(arr[1..-1])
		when "CIRPINGACK";ping_ack_server_circuitm(arr[1..-1])
		when "CIRTRACEROUTEREQ";traceroute_server_circuitm(arr[1..-1])
		when "CIRTRACEROUTEACK"; traceroute_ack_server_circuitm(arr[1..-1])
		when "CIRFTPINTERUPT";ftpinteruptHandler_circuitm(arr[1..-1])
        #circuitD
        when "CIRCUIT_to_delete";circuit_to_delete(arr[1..-1])
        when "CIRCUITD_ACK";circuitd_ack_server(arr[1..-1])
        when "CIRCUITD_fail_ack";circuitd_fail_server(arr[1..-1])



	end
end

# ------------------------------------------------- #
# do main loop here....
def main()
	while(line = STDIN.gets())
		line = line.strip()
		arr = line.split(' ')
		cmd = arr[0]
		args = arr[1..-1]
		case cmd
			when "EDGEB"; edgeb(args)
			when "EDGED"; edged(args)
			when "EDGEU"; edgeu(args)
			when "DUMPTABLE"; dumptable(args)
			when "SHUTDOWN"; shutdown(args)
			when "STATUS"; status()
			when "SENDMSG"; sendmsg(args)
			when "PING"; ping(args)
			when "TRACEROUTE"; traceroute(args)
			when "FTP"; ftp(args)

			when "CIRCUITB"; circuitb(args)
			when "CIRCUITM"; circuitm(args)
			when "CIRCUITD"; circuitd(args)



			else STDERR.puts "ERROR: INVALID COMMAND \"#{cmd}\""
		end
	end

end

def setup(hostname, port, nodefile, config)
	$hostname = hostname
	$port = port
	$updateInterval=10
	$maxPayload=1
	$pingTimeout=5
	$time=0

	costmap = {}
	hopmap = {}

	if File.exist?(config)
		fHandle=File.open(config)
		while line=fHandle.gets
			arr=line.chomp().split('=')
			case
				when arr[0]== "updateInterval";
					$updateInterval=arr[1].to_f
				when arr[0]=="maxPayload";
					$maxPayload=arr[1].to_i
				when arr[0]=="pingTimeout";
					$pingTimeout=arr[1].to_i
			end
		end

	end


	if(File.exist?(nodefile))
		fHandle=File.open(nodefile)
		while(line=fHandle.gets)
			arr=line.chomp().split(',')
			node_name=arr[0]
			node_port=arr[1]
			$node_port[node_name]=node_port
			# build routing table for node n to other nodes, except node n
			if node_name!=$hostname
				costmap[node_name]=nil
				hopmap[node_name]=nil
			end
		end

		# use this to store the routing information for local map.1
		$local_route[$hostname]=CostPackage.new($hostname, costmap, hopmap, 0)

		#set up ports, server, buffers
		$serverThread=Thread.new{listening($port)}
		$readThread=Thread.new{read($sock_array)}
		$mainThread=Thread.new{main()}
		$clockThread=Thread.new{clock()}
		$updateThread=Thread.new{
			loop{
				update()
				sleep $updateInterval
			}
		}

		$pingThread=Thread.new{
			pingchecker()
		}

		threads = []
		threads << $mainThread
		threads << $updateThread
		threads << $serverThread
		threads << $readThread
		threads << $clockThread
		threads << $pingThread
		threads.each { |thr| thr.join }

	end
end

setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])



