require 'spec_helper'

describe 'minecraft::default' do
  context 'install minecraft defaults' do
    let(:chef_run) do
      ChefSpec::Runner.new(:platform => 'debian', :version  => '7.0') do |node|
        node.set['minecraft']['ops'] = %w(gregf sandal82)
        node.set['minecraft']['banned-ips'] = %w(10.1.2.3 10.1.100.10)
        node.set['minecraft']['banned-players'] = %w(gregf sandal82)
        node.set['minecraft']['white-list'] = %w(gregf sandal82)
        node.automatic['memory']['total'] = '2097152kB'
      end.converge(described_recipe)
    end
    let(:minecraft_jar) { '/srv/minecraft/minecraft_server.1.8.7.jar' }

    it 'includes default java recipe' do
      expect(chef_run).to include_recipe('java::default')
    end

    it 'includes the minecraft::user recipe' do
      expect(chef_run).to include_recipe('minecraft::user')
    end

    it 'creates a remote_file with attributes' do
      expect(chef_run).to create_remote_file_if_missing(minecraft_jar).with(
        owner: 'mcserver',
        group: 'mcserver',
        mode: 0644
      )
    end

    it 'creates a directory for the minecraft server to live' do
      expect(chef_run).to create_directory('/srv/minecraft').with(
        user: 'mcserver',
        group: 'mcserver',
        mode: 0755,
        recursive: true
      )
    end

    context 'renders the server.properties template' do
      let(:template) { chef_run.template('/srv/minecraft/server.properties') }

      it 'renders the template' do
        expect(chef_run).to render_file(template.path).with_content('# Minecraft server properties')
      end

      it 'is owned by mcserver:mcserver' do
        expect(template.owner).to eq('mcserver')
        expect(template.group).to eq('mcserver')
      end

      it 'has 0644 permissions' do
        expect(template.mode).to eq(0644)
      end

      it 'notifies runit service' do
        expect(template).to notify('runit_service[minecraft]').to(:restart).delayed
      end

      it 'does not notify upstart service' do
        expect(template).to_not notify('service[minecraft]').to(:restart).delayed
      end
    end


    context 'creates ops.txt' do
      let(:ops) { chef_run.file('/srv/minecraft/ops.txt') }

      it 'creates ops.txt' do
        expect(chef_run).to create_file(ops.path).with_content("gregf\nsandal82\n")
      end

      it 'is owned by mcserver:mcserver' do
        expect(ops.owner).to eq('mcserver')
        expect(ops.group).to eq('mcserver')
      end

      it 'has 0644 permissions' do
        expect(ops.mode).to eq(0644)
      end

      it 'notifies runit service' do
        expect(ops).to notify('runit_service[minecraft]').to(:restart).delayed
      end

      it 'does not notify upstart service' do
        expect(ops).to_not notify('service[minecraft]').to(:restart).delayed
      end
    end

    context 'creates banned-ips.txt' do
      let(:banned_ips) { chef_run.file('/srv/minecraft/banned-ips.txt') }

      it 'creates banned-ips.txt' do
        expect(chef_run).to create_file(banned_ips.path).with_content("10.1.2.3\n10.1.100.10\n")
      end

      it 'is owned by mcserver:mcserver' do
        expect(banned_ips.owner).to eq('mcserver')
        expect(banned_ips.group).to eq('mcserver')
      end

      it 'has 0644 permissions' do
        expect(banned_ips.mode).to eq(0644)
      end

      it 'notifies runit service' do
        expect(banned_ips).to notify('runit_service[minecraft]').to(:restart).delayed
      end

      it 'does not notify upstart service' do
        expect(banned_ips).to_not notify('service[minecraft]').to(:restart).delayed
      end
    end

    context 'creates banned-players.txt' do
      let(:banned_players) { chef_run.file('/srv/minecraft/banned-players.txt') }

      it 'creates banned-ips.txt' do
        expect(chef_run).to create_file(banned_players.path).with_content("gregf\nsandal82\n")
      end

      it 'is owned by mcserver:mcserver' do
        expect(banned_players.owner).to eq('mcserver')
        expect(banned_players.group).to eq('mcserver')
      end

      it 'has 0644 permissions' do
        expect(banned_players.mode).to eq(0644)
      end

      it 'notifies runit service' do
        expect(banned_players).to notify('runit_service[minecraft]').to(:restart).delayed
      end

      it 'does not notify upstart service' do
        expect(banned_players).to_not notify('service[minecraft]').to(:restart).delayed
      end
    end

    context 'creates white-list.txt' do
      let(:white_list) { chef_run.file('/srv/minecraft/white-list.txt') }

      it 'creates banned-ips.txt' do
        expect(chef_run).to create_file(white_list.path).with_content("gregf\nsandal82\n")
      end

      it 'is owned by mcserver:mcserver' do
        expect(white_list.owner).to eq('mcserver')
        expect(white_list.group).to eq('mcserver')
      end

      it 'has 0644 permissions' do
        expect(white_list.mode).to eq(0644)
      end

      it 'notifies runit service' do
        expect(white_list).to notify('runit_service[minecraft]').to(:restart).delayed
      end

      it 'does not notify upstart service' do
        expect(white_list).to_not notify('service[minecraft]').to(:restart).delayed
      end
    end

    context 'creates white-list.txt' do
      let(:eula) { chef_run.file('/srv/minecraft/eula.txt') }

      it 'creates eula.txt' do
        expect(chef_run).to create_file(eula.path).with_content(/^eula=/)
      end

      it 'has 0644 permissions' do
        expect(eula.mode).to eq(0644)
      end

      it 'notifies runit service' do
        expect(eula).to notify('runit_service[minecraft]').to(:restart).delayed
      end

      it 'does not notify upstart service' do
        expect(eula).to_not notify('service[minecraft]').to(:restart).delayed
      end
    end

    it 'includes the minecraft::service recipe' do
      expect(chef_run).to include_recipe('minecraft::service')
      expect(chef_run).to include_recipe('runit')
    end
  end

  describe "on an ubuntu system" do
    let(:chef_run) do
      ChefSpec::Runner.new(:platform => 'ubuntu', :version  => '12.04') do |node|
        node.automatic['minecraft']['init_type'] = 'upstart'
        node.automatic['memory']['total'] = '2097152kB'
      end.converge(described_recipe)
    end

    it 'does not include the minecraft::service recipe' do
      expect(chef_run).to_not include_recipe('minecraft::service')
      expect(chef_run).to_not include_recipe('runit')
    end

    context 'creates the /etc/init/minecraft.conf' do
      let(:template) { chef_run.template('/etc/init/minecraft.conf') }

      it 'creates upstart file' do
        expect(chef_run).to render_file(template.path)
      end

      it 'is owned by root:root' do
        expect(template.owner).to eq('root')
        expect(template.group).to eq('root')
      end

      it 'has 0644 permissions' do
        expect(template.mode).to eq(0644)
      end

      it 'notify service[minecraft]' do
        resource = chef_run.service('minecraft')
        expect(template).to notify('service[minecraft]').to(:restart).delayed
      end

      it 'does not notify runit service' do
        expect(template).to_not notify('runit_service[minecraft]').to(:restart).delayed
      end
    end
  end
end
