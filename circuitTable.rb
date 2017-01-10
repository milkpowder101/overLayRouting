class CircuitTable

  attr_accessor :circuitID, :sourceNode,:destNode,:circuit,:times
  @circuitID
  @sourceNode
  @destNode
  @circuit
  @times

  def initialize(circuitID,sourceNode,destNode,circuit,times)
    @circuitID=circuitID
    @sourceNode=sourceNode
    @destNode=destNode
    @circuit=circuit
    @times=times
  end

  def getTime()
    return @times
  end
  def setTime(time)
    @times=time
  end
  def getSource()
    return @sourceNode
  end
  def getDest()
    return @destNode
  end

  def getCircuit()
    return @circuit
  end

end


