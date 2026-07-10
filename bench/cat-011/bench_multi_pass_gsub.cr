require "benchmark"

puts "=== chained gsub vs single gsub with hash ==="
puts ""

text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

[10, 100, 1_000, 10_000].each do |n|
  str = text * n

  chained = Benchmark.measure {
    str
      .gsub("Lorem", "Ipsum")
      .gsub("ipsum", "dolor")
      .gsub("amet", "elit")
      .gsub("elit", "amet")
      .gsub("consectetur", "adipiscing")
      .gsub("incididunt", "mollit")
  }
  single = Benchmark.measure { str.gsub(/Lorem|ipsum|amet|elit|consectetur|incididunt/, {"Lorem" => "Ipsum", "ipsum" => "dolor", "amet" => "elit", "elit" => "amet", "consectetur" => "adipiscing", "incididunt" => "mollit"}) }
  ratio = single.real > 0 ? (chained.real / single.real).round(2) : Float64::INFINITY

  puts "n=#{n.to_s.ljust(6)}  chained=#{chained.real.round(6).to_s.ljust(9)}s  single=#{single.real.round(6).to_s.ljust(9)}s  #{ratio}x faster"
end
