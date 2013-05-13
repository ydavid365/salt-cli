require 'fog'

module Salt
  module Commands
    class Launch < BaseCommand
      def run(args=[])
        # Hash[vm.config.vm.networks][:hostonly].first,
        vm = find_machine! name
        if vm.state == :running
          puts "The machine is already running. Not launching"
        else
          
          debug "Launching vm..."
          provider.launch(vm)
          
          if true || auto_accept
            debug "Accepting the key"
            Salt::Commands::Key.new(provider, config.merge(force: true, name: name)).run([])
            5.times {|i| print "."; sleep 1; }
          end
        
          if roles
            debug "Assigning the roles #{roles.join(', ')}"
            Salt::Commands::Role.new(provider, config.merge(debug: true, roles: roles.join(','))).run([])
          end
          
        end
      end
      
      def self.additional_options(x)
        x.on("-r", "--roles <roles>", "Roles") {|n| config[:roles] = n.split(",")}
        x.on("-a", "--auto_accept", "Auto accept the new role") {|n| config[:auto_accept] = true}
      end
      
    end
  end
end

Salt.register_command "launch", Salt::Commands::Launch