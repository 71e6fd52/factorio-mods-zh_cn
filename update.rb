#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'factorio/mod'

FileUtils.touch 'mods.lock'

lock = YAML.safe_load(File.open('mods.lock', &:read))
lock ||= {}
mods = File.open('mods', &:read).split("\n").map(&:strip)
FileUtils.rm_rf('tmp')
FileUtils.mkdir_p('tmp')
FileUtils.mkdir_p('omegat/source')

mods.each do |mod|
  mod = Factorio::Mod.new mod
  download = mod.latest_download

  newv = Gem::Version.create(download.version)
  unless lock[mod.name].nil?
    oldv = Gem::Version.create(lock[mod.name]['version'])
    case oldv <=> newv
    when 1
      puts "Warning: #{mod.title} local version(#{oldv}) newer than remote " \
      "version(#{newv})"
    when 0
      puts "#{mod.title} up to date(#{oldv})"
      next
    end
  end

  filename = "#{mod.name}_#{newv}.zip"
  full_filename =
    if `uname -r`.include? 'microsoft-standard'
      File.join('/mnt/c/Users/yahvk/AppData/Roaming/Factorio/mods', filename)
    else
      File.join(ENV['HOME'], '.factorio/mods', filename)
    end

  if File.file? full_filename
    FileUtils.cp full_filename, File.join('tmp', filename)
    system "unar tmp/#{filename} -q -o tmp -f"

    if Dir.exist?("tmp/#{mod.name}_#{newv}/locale")
      system "cat tmp/#{mod.name}_#{newv}/locale/en/* >omegat/source/#{mod.name}.cfg"
    elsif Dir.exist?("tmp/#{mod.name}/locale")
      system "cat tmp/#{mod.name}/locale/en/* >omegat/source/#{mod.name}.cfg"
    else
      puts "Error: Can't find locale file of #{mod.name}"
    end

    lock[mod.name] ||= {}
    lock[mod.name]['version'] = newv.to_s
    puts "Update #{mod.name} to #{newv}."
  else
    puts "Warning: Not found #{mod.name} #{newv}. Download at #{download.uri}"
  end
end

File.open('mods.lock', 'w') { |f| YAML.dump(lock, f) }
