class D2D
	require "/d2dspec/bin/setenv.rb"
	
	BQ_HOME = $env["bq_home"]
	D2D_PATH = $env["d2d_home"]

	BIN_PATH = "#{D2D_PATH}/bin"
	DB_PATH = "#{D2D_PATH}/data"

	D2DNODE = BIN_PATH + "/d2dnode"
	D2DVERIFY = BIN_PATH + "/d2dverify"
	D2DRESTOREVM = BIN_PATH + "/d2drestorevm"
	D2DJOB = BIN_PATH + "/d2djob"

	DB_ARCSERVERDB = "#{DB_PATH}/ARCserveLinuxD2D.db"

	BQ_TMP = "#{BQ_HOME}/tmp"
	BQ_TMP_JOBSCRIPT = "#{BQ_TMP}/jobscript"
	BQ_TMP_VERIFYSCRIPT = "#{BQ_TMP}/verifyscript"
	BQ_BIN = "#{BQ_HOME}/bin"
	BQ_JOBSCRIPT = "#{BQ_HOME}/resource/jobscript"
	BQ_VERIFYSCRIPT = "#{BQ_HOME}/resource/verifyscript"
	BQ_LOG = "#{BQ_HOME}/logs"
	BQ_RESTOREVM_SCRIPT = "#{BQ_HOME}/resource/restorevmscript"
	BQ_TMP_RESTOREVM_SCRIPT = "#{BQ_TMP}/restorevmscript"




######## list all nodes in d2d ################################################
	def D2D.list_node
		$logger.info("test")
		node_info = `#{D2DNODE} --list`
		if $?.exitstatus == 1
			return nil
		else
			node_info_arr = node_info.split("\n").slice(2..-1)
			if !node_info_arr.nil?
				result = node_info_arr.collect do |node|
        				sections = node.split(",")
        				each_node = {:node_name => sections[0].strip, :user_name => sections[1].strip, :job_name => sections[2].strip, :os => sections[3].strip, :desc => sections[4].strip }
				end
			else
				[]
			end
		end
	end

######## add node to d2d server ################################################
	def D2D.add_node(node_name, options={})
		parms = customize_parms options
		$logger.info `#{D2DNODE} --add=#{node_name} #{parms}`
		$?.exitstatus
	end
	
######## discover node to d2d server ################################################
  def D2D.discover_node(options={})
    parms = customize_parms options
    $logger.info `#{D2DNODE} #{parms}`
    $?.exitstatus
  end

######## delete node in d2d ####################################################
	def D2D.delete_node(node_name, options={})
		parms = customize_parms options
		$logger.info `#{D2DNODE} --delete=#{node_name} #{parms}`
    $?.exitstatus
	end

######## submit restore job ####################################################
	def D2D.bmr_verify(verify)
		#`#{D2DVERIFY} --template=#{path}`
		if !verify.nil? && !verify.empty?
			#`cp -f #{BQ_VERIFYSCRIPT}/#{verify} #{BQ_TMP_VERIFYSCRIPT}/#{verify}`
			$logger.info `#{D2DVERIFY} --template=#{BQ_VERIFYSCRIPT}/#{verify}`
			$?.exitstatus
		else
			1
		end
	end


	def D2D.bmr_restorevm(script, options={})
		if !script.nil? && !script.empty?
			`cp #{BQ_RESTOREVM_SCRIPT}/#{script} #{BQ_TMP_RESTOREVM_SCRIPT}/#{script}`
			script_path = "#{BQ_TMP_RESTOREVM_SCRIPT}/#{script}"
			
			options.each do |key, value|
        $logger.info key
        $logger.info value
                       		gsub_file(script_path, /#*#{key} = .*/, "#{key} = #{value}")
	                end



		
                #        `cp -f #{BQ_VERIFYSCRIPT}/#{verify} #{BQ_TMP_VERIFYSCRIPT}/#{verify}`
                        $logger.info `#{D2DRESTOREVM} --template=#{script_path}`
                        $?.exitstatus
                else
			1
		end
	end
######## delete jobs in d2d ####################################################
	def D2D.delete_job(job_name)
		if !job_name.nil? && !job_name.empty?
			$logger.info `#{D2DJOB} --delete=#{job_name}`
			$?.exitstatus
		else
			1
		end
	end

######## submit a backup job ###################################################
	def D2D.submit_backup(suffix = "", options={})
		get_d2d_info
		#`cp -f #{BQ_JOBSCRIPT}/* #{BQ_TMP_JOBSCRIPT}`
		
		threads = []

		if suffix == ""
			Dir.foreach(BQ_JOBSCRIPT) do |file|
				if file != "." and file != ".."
					threads << Thread.new { Thread.current[:res] = submit_one_backup("#{file}", options)  }
				end
			end
		else
			Dir.foreach(BQ_JOBSCRIPT) do |file|
				if file != "." and file != ".." and file =~ /#{suffix}.js$/
					threads << Thread.new { Thread.current[:res] = submit_one_backup("#{file}", options)  }
				end
			end
		end
		
		if threads.size == 0 
			return 200
		end
		res = threads.collect{ |t| t.join; t[:res]}

		res.each do |r|
			# puts r
			return 1 if r != 0
		end
		return 0
	end

	def D2D.submit_one_backup(jobscript, options={})
		get_d2d_info
                `cp -f #{BQ_JOBSCRIPT}/#{jobscript} #{BQ_TMP_JOBSCRIPT}/#{jobscript}`
                
		options.each do |key, value|
      $logger.info key
      $logger.info value
			gsub_file("#{BQ_TMP_JOBSCRIPT}/#{jobscript}", /#{key} = .*/, "#{key} = #{value}") 
		end


		`source #{BIN_PATH}/setenv; export D2D_SERVER_NAME=#{@server_name}; export D2D_SERVER_UUID=#{@server_uuid}; export D2D_SERVER_CHECKLICENSE_URL=#{@check_license_url}; /opt/CA/d2dserver/sbin/d2dbackup --jobscript #{BQ_TMP_JOBSCRIPT}/#{jobscript};`
		#result = $?.exitstatus
		# p $?
		if $?.exitstatus == 0
			$logger.info "Backup job for #{jobscript} is scuccessful."
		elsif $?.exitstatus == 255
			$logger.info "The job for the node is runing."
		else
			"Backup job for #{jobscript} is failed or canceled."
		end
		
		$?.exitstatus
	end






######## private method ########################################################
	def self.customize_parms(options)
		parms = ""
		if !options.nil? && !options.empty?
                        parms=""
                        options.each{|key, value| parms="#{parms} --#{key}=#{value}"}
			parms
		else
			parms
    end
	end

	def self.get_d2d_info()
		@server_uuid = `sqlite3 #{DB_ARCSERVERDB} "select uuid from D2DServer"`.chomp
		@server_name = `sqlite3 #{DB_ARCSERVERDB} "select name from D2DServer"`.chomp
		@check_license_url = "https://#{@server_name}:8014/WebServiceImpl/CheckLicense?"
		#p server_uuid
		#p server_name
		#p check_license_url

#`export D2D_SERVER_NAME=#{server_name}; export D2D_SERVER_UUID=#{server_uuid}; export D2D_SERVER_CHECKLICENSE_URL=#{check_license_url}; /opt/CA/d2dserver/sbin/d2dbackup --jobscript /opt/CA/d2dserver/sbin/f2229f55-6e9c-49d4-a5a5-2b30081b4ce2.js;`


	end

	def self.gsub_file(file, old, new)
		content = File.read(file).gsub(old, new)
		File.open(file, 'wb') { |file| file.write(content) }
	end

	def self.wait_jobs(jobs)
		$logger.info `#{D2DJOB} --wait='#{jobs}'`	
		$?.exitstatus
	end

end