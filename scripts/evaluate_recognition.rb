require "yaml"
require File.expand_path("../../src/appraiser/appraiser.rb", __FILE__)
require File.expand_path("../../src/file_list/file_list.rb", __FILE__)

def avg(array)
  1.0 * array.inject(:+) / array.size
end

def stdev(array)
  avg = avg(array)
  sum = array.inject(0) { |accum, i| accum + (i - avg) ** 2 }
  1.0 * sum / array.size
end

# def median_split(array)
#   c = array.size % 2
#   pos = array.size / 2 - 1, array.size / 2 + c
#   subset = [array[0..pos[0]], array[pos[1]..-1]]
#   m = median array
#   subset[0].push m
#   subset[1].unshift m
#   subset
# end

# def median(array)
#   if array.size.odd?
#     array[array.size / 2]
#   else
#     (array[array.size / 2 - 1].to_f + array[array.size / 2].to_f) / 2
#   end
# end

# returns min, quartile1, quartile3 and max of array
# def box_plot_points(array)
#   array.sort!
#   split = median_split array
#   [array[0], median(split[0]), median(split[1]), array[-1]]
# end

def overall(array)
  {
    "avg" => avg(array),
    "stdev" => stdev(array),
    "n" => array.size
    # "box_plot_points" => box_plot_points(array)
  }
end

raise "Enter a scope_directory for the evaluation" if ARGV.size < 1

scope_directory = ARGV[0]
list = FileList.new(scope_directory)

f_measures = []
precisions = []
recalls = []

list.count.times do |i|
  print "evaluating #{scope_directory} \t #{(100.0 * i / list.size).round(2)}%\n"

  recognized = list.recognized_files[i]
  next unless File.exists? recognized
  ground_truth = list.gt_files[i]
  measure_file = list.measure_files[i]

  evaluation = Appraiser.new(recognized, ground_truth)
  results = evaluation.results

  f_measures << results["f_measure"]
  precisions << results["precision"]
  recalls << results["recall"]

  evaluation.save_results(measure_file)
end

results = {
  "f_measures" => overall(f_measures),
  "precisions" => overall(precisions),
  "recalls" => overall(recalls)
}

File.open("#{list.measures_dir}/overall.yml", "w") do |f|
  f << results.to_yaml
end

print "evaluating #{scope_directory} ok.\n"