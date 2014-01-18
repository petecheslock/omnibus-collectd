# -*- mode: ruby -*-
# vi: set ft=ruby :

require "vagrant"

if Vagrant::VERSION < "1.4.0"
  raise "The Omnibus Build Lab is only compatible with Vagrant 1.4.0+"
end

# This is fixed as part of vagrant 1.5 - monkeypatch it here
# This allows freebsd NFS shared folders to work
require Vagrant.source_root.join("plugins", "provisioners", "chef", "provisioner", "chef_solo")
class VagrantPlugins::Chef::Provisioner::ChefSolo
  def share_folders(root_config, prefix, folders)
    folders.each do |type, local_path, remote_path|
      if type == :host
        root_config.vm.synced_folder(
        local_path, remote_path,
        :id =>  "v-#{prefix}-#{self.class.get_and_update_counter(:shared_folder)}",
        :type => (@config.nfs ? :nfs : nil))
      end
    end
  end
end

host_project_path = File.expand_path("..", __FILE__)
guest_project_path = "/home/vagrant/#{File.basename(host_project_path)}"
project_name = "collectd"
host_name = "#{project_name}-omnibus-build-lab"

Vagrant.configure("2") do |config|

  %w{
    freebsd-8.1_chef-11.4.4
    debian-6.0.8_chef-11.8.0
    ubuntu-12.04_chef-11.8.0
  }.each_with_index do |platform, index|

    config.vm.define platform do |c|

      case platform

      ####################################################################
      # FREEBSD-SPECIFIC CONFIG
      ####################################################################
      when /freebsd/

        use_nfs = true

        # FreeBSD"s mount_nfs does not like paths over 88 characters
        # http://lists.freebsd.org/pipermail/freebsd-hackers/2012-April/038547.html
        ENV["BERKSHELF_PATH"] = File.join("/tmp")
        bootstrap_chef_version = "11.4.4"

        major_version = platform.split(/freebsd-(.*)\..*/).last

        c.vm.guest = :freebsd
        c.vm.box = platform
        c.vm.box_url = "http://dyn-vm.s3.amazonaws.com/vagrant/#{platform}.box"
        c.vm.network :private_network, :ip => "33.33.33.#{50 + index}"

        c.vm.provision :shell, :inline => <<-FREEBSD_SETUP
          sed -i "" -E "s%^([^#].*):setenv=%\1:setenv=PACKAGESITE=ftp://ftp.freebsd.org/pub/FreeBSD/ports/amd64/packages-#{major_version}-stable/Latest,%" /etc/login.conf
        FREEBSD_SETUP

      ####################################################################
      # LINUX-SPECIFIC CONFIG
      ####################################################################
      else
        bootstrap_chef_version = "11.8.0"
        use_nfs = false

        c.vm.box = platform
        c.vm.box_url = "http://dyn-vm.s3.amazonaws.com/vagrant/#{platform}.box"
        c.omnibus.chef_version = bootstrap_chef_version

        c.vm.provider :virtualbox do |vb|
          # Give enough horsepower to build without taking all day.
          vb.customize [
            "modifyvm", :id,
            "--memory", "3072",
            "--cpus", "2"
          ]
        end

      end # case

      ####################################################################
      # CONFIG SHARED ACROSS ALL PLATFORMS
      ####################################################################

      config.berkshelf.enabled = true
      config.ssh.forward_agent = true

      config.vm.synced_folder ".", "/vagrant", :id => "vagrant-root", :nfs => use_nfs
      config.vm.synced_folder host_project_path, guest_project_path, :nfs => use_nfs

      # Uncomment for DEV MODE
      # config.vm.synced_folder File.expand_path("../../omnibus-ruby", __FILE__), "/home/vagrant/omnibus-ruby", :nfs => use_nfs
      # config.vm.synced_folder File.expand_path("../../omnibus-software", __FILE__), "/home/vagrant/omnibus-software", :nfs => use_nfs

      # prepare VM to be an Omnibus builder
      config.vm.provision :chef_solo do |chef|
        chef.nfs = use_nfs
        chef.json = {
          "omnibus" => {
            "build_user" => "vagrant",
            "build_dir" => guest_project_path,
            "install_dir" => "/opt/#{project_name}"
          }
        }

        chef.run_list = [
          "recipe[omnibus::default]"
        ]
      end

      config.vm.provision :shell, :inline => <<-CHEF_APPLY
        chef-apply -e 'package "unzip"'
        chef-apply -e 'package "curl"'
      CHEF_APPLY

      config.vm.provision :shell, :inline => <<-OMNIBUS_BUILD
        export PATH=/usr/local/bin:$PATH
        cd #{guest_project_path}
        su vagrant -c "curl http://curl.haxx.se/ca/cacert.pem > ~/cacert.pem"
        su vagrant -c "bundle install --binstubs"
        su vagrant -c "SSL_CERT_FILE=/home/vagrant/cacert.pem bin/omnibus build project #{project_name}"
      OMNIBUS_BUILD

    end # config.vm.define.platform
  end # each_with_index
end # Vagrant.configure
