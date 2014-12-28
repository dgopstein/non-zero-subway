non-zero-subway
===============

An economical model of passenger behavior in subway cars

Running the algorithm comparison:
rvm use jruby
jruby --2.0 -S irb
([ENV['HOME']+'/deep_enumerable/lib/deep_enumerable.rb']+Dir[Dir.pwd+'/*.rb']).each{|x| load x}
compare_algos

Running the inspector:
rvm use jruby
jruby --2.0 -S irb
([ENV['HOME']+'/deep_enumerable/lib/deep_enumerable.rb']+Dir[Dir.pwd+'/*.rb']).each{|x| load x}
run_inspector