Dir.glob("src/catalyst/rules/*.cr").sort.each do |file|
  basename = File.basename(file)
  next if basename == "base.cr"
  puts "require \"./catalyst/rules/#{basename}\""
end
