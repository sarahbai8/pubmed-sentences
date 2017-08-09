#
# prematurity.jl
#

using BioMedQuery.Entrez
using MySQL

# use the helper file
include("prematurity_helpers.jl")

# use esearch to find the mesh descriptors
premature_data_array = pubmed_search("\"premature birth\"[mh]", "prematurity1_output.txt", "sentence_output.txt")
parturition_data_array = pubmed_search("\"parturition\"[mh] NOT \"premature birth\"[mh]", "prematurity1_output.txt", "sentence_output.txt")

# assign varibales to dictionaries in array
premature_mesh_count = premature_data_array[1]
parturition_mesh_count = parturition_data_array[1]
premature_predicate_count = premature_data_array[2]
parturition_predicate_count = parturition_data_array[2]

# print mesh descriptor and count in both searches into a new file
mesh_count_output_file = open("mesh_count_output.txt", "w")
mesh_frequency_file = open("mesh_frequency_output.txt", "w")
already_seen_mesh_descriptors = Set()
for mesh_descriptor in sort(collect(keys(premature_mesh_count)))
  parturition_count = 0
  if haskey(parturition_mesh_count, mesh_descriptor)
    parturition_count = parturition_mesh_count[mesh_descriptor]
  end
  write(mesh_count_output_file,
    "$mesh_descriptor | $(premature_mesh_count[mesh_descriptor]) | $(parturition_count)\n")
  push!(already_seen_mesh_descriptors, mesh_descriptor)
  frequency_count = tf_idf(premature_mesh_count[mesh_descriptor], parturition_count)
  write(mesh_frequency_file, "$mesh_descriptor | $frequency_count\n")
end
for mesh_descriptor in sort(collect(keys(parturition_mesh_count)))
  premature_count = 0
  if haskey(premature_mesh_count, mesh_descriptor)
    premature_count = premature_mesh_count[mesh_descriptor]
  end
  if !(mesh_descriptor in already_seen_mesh_descriptors)
    write(mesh_count_output_file,
      "$mesh_descriptor | $premature_count | $(parturition_mesh_count[mesh_descriptor])\n")
    frequency_count = tf_idf(premature_count, parturition_mesh_count[mesh_descriptor])
    write(mesh_frequency_file, "$mesh_descriptor | $frequency_count\n")
  end
end
close(mesh_count_output_file)
close(mesh_frequency_file)

# print predicate and count in both searches into a new file
predicate_count_output_file = open("predicate_count_output.txt", "w")
predicate_frequency_file = open("predicate_frequency_output.txt", "w")
already_seen_predicate_descriptors = Set()
for predicate in sort(collect(keys(premature_predicate_count)))
  parturition_count = 0
  if haskey(parturition_predicate_count, predicate)
    parturition_count = parturition_predicate_count[predicate]
  end
  write(predicate_count_output_file,
    "$predicate | $(premature_predicate_count[predicate]) | $(parturition_count)\n")
  push!(already_seen_predicate_descriptors, predicate)
  frequency_count = tf_idf(premature_predicate_count[predicate], parturition_count)
  write(predicate_frequency_file, "$predicate | $frequency_count\n")
end
for predicate in sort(collect(keys(parturition_predicate_count)))
  premature_count = 0
  if haskey(premature_predicate_count, predicate)
    premature_count = premature_predicate_count[predicate]
  end
  if !(predicate in already_seen_predicate_descriptors)
    write(predicate_count_output_file,
      "$predicate | $premature_count | $(parturition_predicate_count[predicate])\n")
    frequency_count = tf_idf(premature_count, parturition_predicate_count[predicate])
    write(predicate_frequency_file, "$predicate | $frequency_count\n")
  end
end
close(predicate_count_output_file)
close(predicate_frequency_file)
