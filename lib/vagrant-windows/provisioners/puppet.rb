module Vagrant
  	module Provisioners
    	class Puppet < Base
    		def run_puppet_client
		        options = [config.options].flatten
		        if env[:vm].config.vm.guest == :windows
		        	options << "--modulepath '#{@module_paths.values.join(';')}'" if !@module_paths.empty?
		        else
		        	options << "--modulepath '#{@module_paths.values.join(':')}'" if !@module_paths.empty?
		        end
		        
		        options << @manifest_file
		        options = options.join(" ")

		        # Build up the custom facts if we have any
		        facter = ""
		        if !config.facter.empty?
		          facts = []
		          config.facter.each do |key, value|
		            facts << "FACTER_#{key}='#{value}'"
		          end

		          facter = "#{facts.join(" ")} "
		        end
		        if env[:vm].config.vm.guest == :windows
		        	command = "cd #{manifests_guest_path}; if($?) \{ #{facter}puppet apply #{options} \}"
		        else
		        	command = "cd #{manifests_guest_path} && #{facter}puppet apply #{options}"
		        end

		        env[:ui].info I18n.t("vagrant.provisioners.puppet.running_puppet",
		                             :manifest => @manifest_file)

		        env[:vm].channel.sudo(command) do |type, data|
		          env[:ui].info(data.chomp, :prefix => false)
		        end
	    	end
			def verify_binary(binary)
			  if env[:vm].config.vm.guest == :windows
		      	command = "command #{binary}"
		      else
		      	command = "which #{binary}"
		      end
	          env[:vm].channel.sudo(command,
	                              :error_class => PuppetError,
	                              :error_key => :not_detected,
	                              :binary => binary)
	        end
	        def verify_shared_folders(folders)
		        folders.each do |folder|
		          @logger.debug("Checking for shared folder: #{folder}")

		          
		          if env[:vm].config.vm.guest == :windows
			       	if !env[:vm].channel.test("if(-not (test-path #{folder})) \{exit 1\} ")
		            	raise PuppetError, :missing_shared_folders
		          	end
			      else
			       	if !env[:vm].channel.test("test -d #{folder}")
            			raise PuppetError, :missing_shared_folders
         			end
			      end

		        end
	      	end
     	end
  	end
end
