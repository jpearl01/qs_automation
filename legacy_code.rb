
   #  		if row['Sample'] == 'NC' && row['Target'] == 'SARS'
   #  			nc = nc + 1
   #  			sample_results["NC#{nc}"] = {}
   #  			sample_results["NC#{nc}"]['SARS'] = row['Cq']
			# 	sample_results["NC#{nc}"]['well'] = row['Well Position']
   #  		elsif row['Sample'] == 'NC'
   #  			sample_results["NC#{nc}"][row['Target']] = row['Cq']
			# 	sample_results["NC#{nc}"]['well'] = row['Well Position']
   #  		elsif row['Sample'] == 'PC' && row['Target'] == 'SARS'
   #  			pc = pc + 1
   #  			sample_results["PC#{pc}"] = {}
   #  			sample_results["PC#{pc}"]['SARS'] = row['Cq']
			# 	sample_results["PC#{pc}"]['well'] = row['Well Position']
   #  		elsif row['Sample'] == 'PC'
   #  			sample_results["PC#{pc}"][row['Target']] = row['Cq']
			# 	sample_results["PC#{pc}"]['well'] = row['Well Position']
   #  		else
   #  			sample_results[row['Sample']] = {} unless sample_results.has_key?(row['Sample'])
			# 	sample_results[row['Sample']][row['Target']] = row['Cq']
			# 	sample_results[row['Sample']]['well'] = row['Well Position']
			# end