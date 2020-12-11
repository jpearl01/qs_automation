require 'csv'
require 'time'
require 'fox16'
include Fox


class HelloWorld < FXMainWindow
  def initialize(app)
    super(app, "Calculate QS Values" , :width => 250, :height => 100)
	sample_results = {}
    vFrame1 = FXVerticalFrame.new(self, opts: PACK_UNIFORM_HEIGHT|PACK_UNIFORM_WIDTH)
    hFrame1 = FXHorizontalFrame.new(vFrame1, opts: PACK_UNIFORM_HEIGHT)
    hFrame2 = FXHorizontalFrame.new(vFrame1, opts: PACK_UNIFORM_HEIGHT)
    loadButton = FXButton.new(hFrame1, "Load Input" )
    saveButton = FXButton.new(hFrame2, "First Load Input")
    $curr_date = Time.now

    loadButton.connect(SEL_COMMAND)  do
    	dialog = FXFileDialog.new(self, "Load a File")
    	dialog.directory = 'c:\users\josh\Dropbox\database\cryotrack\quantstudio_outputs'  
		dialog.selectMode = SELECTFILE_EXISTING  
		dialog.patternList = ["All Files (*)"]  
		if dialog.execute != 0  
		  load_file(dialog.filename, sample_results)
		  loadButton.text = "Loaded!" 
		  saveButton.text = "Compute and Save"
		end  
    end

    saveButton.connect(SEL_COMMAND)  do
    	dialog = FXDirDialog.new(self, "Select Save Directory")
    	dialog.directory = 'c:\users\josh\Dropbox\database\cryotrack\quantstudio_outputs'
    	save_dir = ''
		if dialog.execute != 0  
		  save_dir = dialog.directory
		  fn_redcap = File.join(save_dir, "CoM-COVID-Results-" + Time.now.strftime("%Y-%m-%d-%H%M") + ".csv")
		  fn_cryotrack = File.join(save_dir, "CoM-COVID-Results-" + Time.now.strftime("%Y-%m-%d-%H%M") + "_cryotrack.csv")
		  save_file(fn_redcap, fn_cryotrack, sample_results)
		  saveButton.text = "Finished!"
		end  
		`explorer #{dialog.directory}`
		exit
    end

    def load_file(filename, sample_results)  
    	check_index = 0

    	File.readlines(filename).each do |line|
    		next unless line.match(/Plate Run Start Date/)
    		time_str = line.gsub(/# Plate Run Start Date\/Time: /, '')
    		$curr_date = Time.parse(time_str.chomp!)
    		break if line.match(/Plate Run Start Date/)
    	end

    	CSV.foreach(filename, skip_lines: /^#/, headers: true) do |row|  
    		#Some samples are either '0' or not there, meaning we should skip this sample
    		next unless row['Sample'] != 0 && !row['Sample'].nil? && row['Sample'] != '0'
    		#apparently any sample that doesn't follow the 6digit-5digit convention should be skipped
    		next unless row['Sample'].match(/\d{6}-\d{5}|PC|NC/)
    		#Sanity check: does the file have the columns we need?
    		if check_index == 0
    			abort "The loaded file does not contain the 'Well Position' column" unless !row['Well Position'].nil?
    			abort "The loaded file does not contain the 'Sample' column" unless !row['Sample'].nil?
    			abort "The loaded file does not contain the 'Target' column" unless !row['Target'].nil?
    			abort "The loaded file does not contain the 'Cq' column" unless !row['Cq'].nil?
    			check_index = 1
    		end
    		#If we have missing data, abort. Something wrong with file
    		abort "Target doesn't exist at line #{$.}: #{row}" if row['Target'].nil?
    		abort "Cq doesn't exist at line #{$.}: #{row}" if row['Cq'].nil?

    		#Finally add data to our hash, for later processing in the 'save_file' function
			sample_results[row['Well Position']] = {} unless sample_results.has_key?(row['Well Position'])
			sample_results[row['Well Position']][row['Target']] = row['Cq']
			sample_results[row['Well Position']]['Sample'] = row['Sample']
    	end 
  	end 

  	def save_file(fn_redcap, fn_cryotrack, sample_results)
    	# redcap = File.open(fn_redcap, 'wb')
    	cryotrack = File.open(fn_cryotrack, 'wb')
    	date_str = $curr_date.strftime("%m/%d/%Y")

		cryotrack.puts("Well,Sample Name,Date,SARS_val,IC_val,RNaseP_val,SARS_result,IC_result,RNaseP_result,Result,Comments") 
    	# redcap.puts ("Sample Name,Date,Covid Result,Comments")

    	sample_results.each_key do |key|
    		sars = ''
    		ic = '' 
    		rnasep = ''
    		all_three = ''
    		comment = ''
    		result = 'SOMETHING_BAD_HAPPENED'
    		if sample_results[key]['SARS'].match(/undetermined/im) 
    			sars = '-'
    		elsif sample_results[key]['Sample'] =='PC'
    			if sample_results[key]['SARS'].to_f <= 33
    				sars = '+'
    			else
    				sars = '-'
    			end 
    		elsif sample_results[key]['SARS'].to_f < 38
    			sars = '+'
    			comment = comment + "superspreader " if sample_results[key]['SARS'].to_f < 25
    			comment = comment + "Check SARS result-close to threshold " if sample_results[key]['SARS'].to_f > 36
    		else    			
    			sars = '-'
    			comment = comment + "Check SARS result-close to threshold " if sample_results[key]['SARS'].to_f < 40
    		end
    				
    		if sample_results[key]['IC'].match(/undetermined/im)
    			ic = '-' 
    		elsif sample_results[key]['Sample']=='PC'
    			if sample_results[key]['IC'].to_f <= 32
    				ic = '+'
    			else
    				ic = '-'
    			end
    		elsif sample_results[key]['Sample'] =='NC'
    			if sample_results[key]['IC'].to_f <= 32
    				ic = '+'
    				comment = comment + "Check IC result-close to threshold " if sample_results[key]['SARS'].to_f > 31
    			else
    				ic = '-'
    				comment = comment + "Check IC result-close to threshold " if sample_results[key]['SARS'].to_f < 33
    			end
    		elsif sample_results[key]['IC'].to_f < 32
    			ic = '+'
    		else
    			ic = '-'
    		end

    		if sample_results[key]['RNaseP'].match(/undetermined/im) 
    			rnasep = '-' 
    		elsif sample_results[key]['RNaseP'].to_f < 38
    			rnasep = '+'
    		else
    			rnasep = '-'
    		end
    		all_three = sars + ic + rnasep
    		if all_three == '--+' || all_three == '---'
    			result = 'inconclusive'
    		elsif all_three == '-++'
    			result = 'negative'
    		elsif all_three == '-+-' && sample_results[key]['Sample'] != 'NC'
    			result = 'inconclusive'
    		elsif all_three == '-+-' && sample_results[key]['Sample'] == 'NC'
    			result = 'negative'
    		elsif sars == '+'
    			result = 'positive'
    		end
    				

    		cryotrack.puts [key,
    			sample_results[key]["Sample"],
    			date_str,
    			sample_results[key]["SARS"],
    			sample_results[key]["IC"],
    			sample_results[key]["RNaseP"],
    			sars,ic,rnasep,result,comment].join(",") 

			# redcap.puts [sample_results[key]["Sample"], 
			# 	date_str,
			# 	result,
			# 	comment].join(",")
    	end
    	#redcap.close
    	cryotrack.close
    end

  end


  def create
    super
    show(PLACEMENT_SCREEN)
  end

end

app = FXApp.new
HelloWorld.new(app)
app.create
app.run
