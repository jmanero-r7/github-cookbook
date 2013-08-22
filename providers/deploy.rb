#
# Cookbook Name:: github
# Provider:: deploy
#
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
#

use_inline_resources

action :deploy do
  [ new_resource.release_path, new_resource.shared_path ].each do |path|
    directory path do
      owner     new_resource.owner
      group     new_resource.group
      mode      0770
      recursive true
    end
  end

  new_resource.shared_directories.each do |path|
    directory "#{new_resource.shared_path}/#{path}" do
      owner     new_resource.owner
      group     new_resource.group
      mode      0770
      recursive true
    end
  end

  github_archive new_resource.repo do
    version    new_resource.version
    user       new_resource.user
    password   new_resource.password
    host       new_resource.host
    extract_to new_resource.deploy_path
    force      new_resource.force
    action     :extract
  end

  ruby_block "before-migrate" do
    block do
      if new_resource.before_migrate
        Chef::Log.info "github_deploy[#{new_resource.name}] Running before migrate proc"
        recipe_eval(&new_resource.before_migrate.to_proc)
      end
    end
  end

  ruby_block "migrate" do
    block do
      if new_resource.migrate
        Chef::Log.info "github_deploy[#{new_resource.name}] Running migrate proc"
        recipe_eval(&new_resource.migrate.to_proc)
      end
    end
  end

  ruby_block "after-migrate" do
    block do
      if new_resource.after_migrate
        Chef::Log.info "github_deploy[#{new_resource.name}] Running after migrate proc"
        recipe_eval(&new_resource.after_migrate.to_proc)
      end
    end
  end

  link current_path do
    to    new_resource.deploy_path
    owner new_resource.owner
    group new_resource.group
  end
end

private

  def current_path
    ::File.join(new_resource.path, "current")
  end