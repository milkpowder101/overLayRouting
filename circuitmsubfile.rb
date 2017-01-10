require_relative 'messagesubfile'

def circuitm(cmd)
  circuitID=cmd[0].to_i
  message=cmd[1]
  destNode=cmd[2]
  information=cmd[3..-1]

  if !$circuitTalbe.has_key?(circuitID.to_i)
    STDOUT.puts "CIRCUITM ERROR: HOST UNREACHABLE"
    return
  end

  temp=$circuitTalbe[circuitID]
  source=temp.instance_variable_get(:@sourceNode)

  if source!=$hostname
    STDOUT.puts "NOT SOURCE,CANNOT SEND"
    return
  end

    if message=="SENDMSG"
      circuit=temp.getCircuit()
      if circuit.include?(destNode)
        information=information<<destNode
        information=information.join(" ")
        sendmsg_circuitm(circuitID,information)

      else
        STDOUT.puts("CIRCUITM SENDMSG ERROR:HOST UNREACHABLE")
      end


    elsif message=="PING"
      circuit=temp.getCircuit()
      if circuit.include?(destNode)
        information=information<<destNode
        information=information.join(" ")
        ping_circuitm(circuitID,information)

      else
        STDOUT.puts("CIRCUITM PING ERROR:HOST UNREACHABLE")
      end


    elsif message == "TRACEROUTE"
      circuit=temp.getCircuit()
      if circuit.include?(destNode)
        information=information<<destNode
        information=information.join(" ")
        traceroute_circuitm(circuitID,information)
      else
        STDOUT.puts("CIRCUITM TRACEROUTE ERROR:HOST UNREACHABLE")
      end

    elsif message=="FTP"
      circuit=temp.getCircuit()
      if circuit.include?(destNode)
        information=information<<destNode
        information=information.join(" ")
        ftp_circuitm(circuitID,information)
      else
        STDOUT.puts("CIRCUITM FTP ERROR:HOST UNREACHABLE")
      end

    end

end




