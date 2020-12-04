require 'csv'
require 'fox16'
include Fox


class HelloWorld < FXMainWindow
  def initialize(app)
    super(app, "Calculate QS Values" , :width => 250, :height => 100)
	sample_results = {}
    vFrame1 = FXVerticalFrame.new(self, :opts => LAYOUT_FILL)
    hFrame1 = FXHorizontalFrame.new(vFrame1)
    hFrame2 = FXHorizontalFrame.new(vFrame1)
    loadButton = FXButton.new(hFrame1, "Open File")
    saveButton = FXButton.new(hFrame2, "Save File")

    loadButton.connect(SEL_COMMAND)  do
    	dialog = FXFileDialog.new(self, "Load a File")  
		dialog.selectMode = SELECTFILE_EXISTING  
		dialog.patternList = ["All Files (*)"]  
		if dialog.execute != 0  
		  load_file(dialog.filename, sample_results)
		  loadButton.text = "Loaded!" 
		end  
    end

    saveButton.connect(SEL_COMMAND)  do
    	dialog = FXDirDialog.new(self, "Select Save Directory")
    	dialog.directory = 'c:\users\public\documents'
    	save_dir = ''
		if dialog.execute != 0  
		  save_dir = dialog.directory
		  fn = File.join(save_dir, "CoM-COVID-Results-" + Time.now.strftime("%Y-%m-%d-%H%M") + ".csv")
		  save_file(fn, sample_results)
		  saveButton.text = "Saved!"
		end  
    end

    def load_file(filename, sample_results)  
    	check_index = 0
    	CSV.foreach(filename, skip_lines: /^#/, headers: true) do |row|  
    		next unless row['Sample'] != 0 && !row['Sample'].nil?
    		if check_index == 0
    			abort "The loaded file does not contain the 'Sample' column" unless !row['Sample'].nil?
    			abort "The loaded file does not contain the 'Target' column" unless !row['Target'].nil?
    			abort "The loaded file does not contain the 'Cq' column" unless !row['Cq'].nil?
    			check_index += 1
    		end
    		#abort "Sample doesn't exist at line #{$.}: #{row}" if row['Sample'].nil?
    		abort "Target doesn't exist at line #{$.}: #{row}" if row['Target'].nil?
    		abort "Cq doesn't exist at line #{$.}: #{row}" if row['Cq'].nil?

			sample_results[row['Well Position']] = {} unless sample_results.has_key?(row['Well Position'])
			sample_results[row['Well Position']][row['Target']] = row['Cq']
			sample_results[row['Well Position']]['Sample'] = row['Sample']
    	end 

  	end 

  	def save_file(filename, sample_results)
    	File.open(filename, 'wb') do |csv|
    		csv.puts("Well,Sample Name,SARS_val,IC_val,RNaseP_val,SARS_result,IC_result,RNaseP_result,Result") 
	    	sample_results.each_key do |key|
	    		sars = ''
	    		ic = '' 
	    		rnasep = ''
	    		all_three = ''
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
	    		else    			
	    			sars = '-'
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
	    			else
	    				ic = '-'
	    			end
	    		elsif sample_results[key]['IC'].to_f < 38
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
	    			result = 'invalid'
	    		elsif all_three == '-++' || all_three == '-+-'
	    			result = 'negative'
	    		elsif sars == '+'
	    			result = 'positive'
	    		end
	    				

	    		csv.puts [key,
	    			sample_results[key]["Sample"],
	    			sample_results[key]["SARS"],
	    			sample_results[key]["IC"],
	    			sample_results[key]["RNaseP"],
	    			sars,ic,rnasep,result].join(",") 
	    	end
	    end
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
