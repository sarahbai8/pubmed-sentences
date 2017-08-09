#
# obstetric_labor.jl
#

using BioMedQuery.Entrez
using MySQL

# use the helper file
include("prematurity_helpers.jl")

mesh_descriptors_array = ["\"Abruptio Placentae\"[mh]", "\"Breech Presentation\"[mh]", "\"Cephalopelvic Disproportion\"[mh]",
                          "\"Dystocia\"[mh]", "\"Fetal Membranes, Premature Rupture\"[mh]", "\"Obstetric Labor, Premature\"[mh]",
                          "\"Placenta Accreta\"[mh]", "\"Placenta Previa\"[mh]", "\"Postpartum Hemorrhage\"[mh]",
                          "\"Uterine Inversion\"[mh]", "\"Uterine Rupture\"[mh]", "\"Vasa Previa\"[mh]"]

for search_term in mesh_descriptors_array
  mesh_descriptor_data_array = pubmed_search(search_term)

  mesh_descriptor_mesh_count = mesh_descriptor_data_array[1]
  mesh_descriptor_predicate_count = mesh_descriptor_data_array[2]

  # print mesh descriptor and count in both searches into a new file
  mesh_count_output_file = open("mesh_count_output.txt", "w")
  mesh_frequency_file = open("mesh_frequency_output.txt", "w")
  for mesh_descriptor in sort(collect(keys(mesh_descriptor_mesh_count)))
    mesh_descriptor_count = 0
    if haskey(mesh_descriptor_mesh_count, mesh_descriptor)
      mesh_descriptor_count = mesh_descriptor_mesh_count[mesh_descriptor]
    end
    write(mesh_count_output_file,
      "$mesh_descriptor | $(mesh_descriptor_mesh_count[mesh_descriptor]) | $(mesh_descriptor_count)\n")
    frequency_count = tf_idf(mesh_descriptor_mesh_count[mesh_descriptor], mesh_descriptor_count)
    write(mesh_frequency_file, "$mesh_descriptor | $frequency_count\n")
  end
  close(mesh_count_output_file)
  close(mesh_frequency_file)

  # print predicate and count in both searches into a new file
  predicate_count_output_file = open("predicate_count_output.txt", "w")
  predicate_frequency_file = open("predicate_frequency_output.txt", "w")
  for predicate in sort(collect(keys(mesh_descriptor_predicate_count)))
    mesh_descriptor_count = 0
    if haskey(parturition_predicate_count, predicate)
      mesh_descriptor_count = mesh_descriptor_predicate_count[predicate]
    end
    write(predicate_count_output_file,
      "$predicate | $(mesh_descriptor_predicate_count[predicate]) | $(mesh_descriptor_count)\n")
    frequency_count = tf_idf(mesh_descriptor_predicate_count[predicate], mesh_descriptor_count)
    write(predicate_frequency_file, "$predicate | $frequency_count\n")
  end
  close(predicate_count_output_file)
  close(predicate_frequency_file)
end
