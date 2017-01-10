class Pqueue
  @queue
  @hashMap
  def initialize()
    @queue=Array.new
    @hashMap=Hash.new
  end

  def push(key, value)
    @hashMap[key] = value
    if(@queue.empty?)
      @queue.push(key)
    else
      i = findIndex(value)
      @queue.insert(i, key)
    end
  end

  def isEmpty()
    return @queue.empty?
  end

  def print()
    @queue.each{|value| puts "#{value} :   #{@hashMap[value]}"};
    #@hashMap.each{|key, value| puts "#{key} : #{value}"};
  end

  def pop()
    node = @queue[0]
    @queue.delete_at(0)
    value = @hashMap[node]
    @hashMap.delete(node)
    return node, value
  end


  def findIndex(value)
    if @hashMap[@queue[@queue.length - 1]].to_i <= value
      return @queue.length
    elsif @hashMap[@queue[0]].to_i >= value
      return 0;
    end

    left = 0;
    right = @queue.length - 1;

    while(left < right)
      mid = left + (right - left ) / 2;
      if(@hashMap[@queue[mid]].to_i == value)
        return mid;
      end
      if(@hashMap[@queue[mid]].to_i < value)
        left = mid + 1;
      else
        right = mid - 1;
      end
    end

    if(@hashMap[@queue[left]].to_i > value)
      return left;
    else
      return left + 1;
    end
  end

end



