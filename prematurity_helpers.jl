#
# prematurity_helpers.jl
#

function pubmed_search(search_term, output_file_name, sentence_output_file_name)
  search_dict1 = Dict("db" => "pubmed", "term" => search_term,
    "retmax" => 400, "email" => "sarah_bai@brown.edu")

  search_result_string1 = esearch(search_dict1)

  # split the esearch string and extract the PMIDs
  pmid_set = Set()
  for result_line in split(search_result_string1, "\n")
    captured_items = match(r"<Id>(\d+)<\/Id>", result_line)
    if captured_items != nothing
      pmid = captured_items[1]
      push!(pmid_set, pmid)
    end
  end

  # use efetch
  fetch_dict1 = Dict("db"=>"pubmed", "email" => "sarah_bai@brown.edu",
              "retmode" => "xml", "rettype"=>"null")
  id_array = collect(pmid_set)
  mesh_count_dict = Dict()
  pmid_array = []
  mesh_heading_dict = Dict()
  batch_size = 300
  num_results_done = 0
  while num_results_done < length(id_array)
    beg_range = num_results_done + 1
    end_range = 0
    if (num_results_done + batch_size) < length(id_array)
      end_range = num_results_done + batch_size
    else
      end_range = length(id_array)
    end
    id_array_batch = id_array[beg_range:end_range]

    println("running e-fetch for batch $(beg_range) to $(end_range)")

    efetch_result1 = efetch(fetch_dict1, id_array_batch)
    num_results_done = num_results_done + batch_size

    # pull out the mesh descriptors
    parsed_dict = eparse(efetch_result1)
    article_dict_array = parsed_dict["PubmedArticle"]
    for article_dict in article_dict_array
      mesh_dict_array = article_dict["MedlineCitation"][1]["MeshHeadingList"][1]["MeshHeading"]
      pmid = article_dict["MedlineCitation"][1]["PMID"][1]["PMID"][1]
      for mesh_dict in mesh_dict_array
        mesh_heading = mesh_dict["DescriptorName"][1]["DescriptorName"][1]
        if haskey(mesh_heading_dict, pmid)
          push!(mesh_heading_dict[pmid], mesh_heading)
        else
          mesh_heading_dict[pmid] = [mesh_heading]
        end
        if haskey(mesh_count_dict, mesh_heading)
          mesh_count_dict[mesh_heading] += 1
        else
          mesh_count_dict[mesh_heading] = 1
        end
      end
      if pmid != nothing
        push!(pmid_array, pmid)
      end
    end
  end

  println("Building MESH descriptors output file...")

  # create an output file to print mesh descriptors
  output_file = open(output_file_name, "w")
  for mesh_index in 1:length(pmid_array)
    this_pmid = pmid_array[mesh_index]
    mesh_headings = join(mesh_heading_dict[this_pmid], ", ")
    write(output_file, "$(this_pmid)|$(mesh_headings)\n")
  end
  close(output_file)

  # connect to the database
  con = mysql_connect("pbcbicit.services.brown.edu", "bcbi_edu_shared", "qMq336GyG431x", "semmed")


  println("Building sentences output file...")

  predicate_count_dict = Dict()
  # print predicate results to an output file
  sentence_output_file = open(sentence_output_file_name, "w")
  for pmid_index in 1:length(pmid_array)
    this_pmid = pmid_array[pmid_index]
    command = "SELECT s.PMID, sp.SUBJECT_TEXT, p.PREDICATE, sp.OBJECT_TEXT FROM SENTENCE_PREDICATION AS sp
      INNER JOIN SENTENCE AS s ON sp.SENTENCE_ID = s.SENTENCE_ID
      INNER JOIN PREDICATION AS p ON sp.PREDICATION_ID = p.PREDICATION_ID
      WHERE s.PMID = \"$this_pmid\";"
    sentence_tuple_array = mysql_execute(con, command, opformat=MYSQL_TUPLES)
    sentence_array = []
    for row in sentence_tuple_array
      sentence_string = "$(get(row[2])) $(row[3]) $(get(row[4]))"
      push!(sentence_array, sentence_string)
    end
    write(sentence_output_file, "Using PMID: $(this_pmid)\n")
    for sentence in sentence_array
      write(sentence_output_file, "$(sentence)\n")
      if haskey(predicate_count_dict, sentence)
        predicate_count_dict[sentence] += 1
      else
        predicate_count_dict[sentence] = 1
      end
    end
  end
  close(sentence_output_file)
  return [mesh_count_dict, predicate_count_dict]
end
