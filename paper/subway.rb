def u(l, x)
  return 0 if (l < 0.0001)

  l*x + (1/2.0)*(u(l*(1-x), x) + u(l*(1-x), 1 - x))
end

def play(x, iter=10)
  line = [1.to_r]
  players = [0.to_r, 1.to_r]
  scores = [2.to_r, 1.to_r]
  score = 0.to_r

  (1..iter).each do |i|
    max = line.max
    
    max_i = 
      if i.even?
        line.index max
      else
        line.rindex max
      end

    line[max_i] = [max*x, max*(1-x)]
    line.flatten!
    players << line.take(max_i + 1).inject(:+)


    segments = line.each_with_object([0]){|elem, sum| sum << sum[-1] + elem}.drop(1)

    #puts

    
    player = players[2]
    j = segments.find_index{|x| x == player}
    min = [(segments[j-1] - player).abs , (segments[j+1] - player).abs].min
    score += min

    #p [min, score]

    # update scores
    #scores[0] += segments[0]
    #players.each_with_index.map.drop(1).each do |player, i|
    #  j = segments.find_index{|x| x == player}

    #  first, last = 
    #    if j == 0
    #      [Rational(1), segments[1]]
    #    elsif j == segments.length - 1
    #      [segments[-2], Rational(2)]
    #    else
    #      f, _, l = segments[j-1, 3]
    #      [f, l]
    #    end
    #  segs = [first, last]
    #  puts "p#{i}@#{players[i]}: #{segs.inspect}"
    #  utility = segs.compact.map{|x| (x - player).abs}.min
    #  scores[i] ||= Rational(0)
    #  scores[i] += utility
    #end

    #puts "line: " + line.inspect
    #puts "play: " + players.inspect
    #puts "segs: " + segments.inspect
    #puts "scor: " + scores.inspect
  end

  score.to_f

end
