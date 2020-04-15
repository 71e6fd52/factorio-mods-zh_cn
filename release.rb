#!/usr/bin/env ruby
# frozen_string_literal: true

require 'tty-prompt'
require 'json'
require 'yaml'
require 'fileutils'

prompt = TTY::Prompt.new

version = File.open('VERSION', &:read).strip
increment = prompt.select("#{version} bumps:", %w[major minor patch null])

unless increment == 'null'
  current, prerelease = version.split('-')
  major, minor, patch, *other = current.split('.')
  case increment
  when 'major'
    major = major.succ
    minor = 0
    patch = 0
    prerelease = nil
  when 'minor'
    minor = minor.succ
    patch = 0
    prerelease = nil
  when 'patch'
    patch = patch.succ
  else
    raise InvalidIncrementError
  end
  version = [major, minor, patch, *other].compact.join('.')
  version = [version, prerelease].compact.join('-')

  File.open('VERSION', 'w') { |f| f.puts version }
end

info = {
  name: '71e6fd52-zh_CN',
  version: version,
  title: '71e6fd52 的 MOD 汉化',
  author: '71e6fd52',
  contact: '71e6fd52 at gmail dot com',
  homepage: 'https://github.com/71e6fd52/factorio-mods-zh_cn',
  description: '71e6fd52 自用汉化',
  factorio_version: '0.18',
  dependencies: [],
}

lock = YAML.safe_load(File.open('mods.lock', &:read))
lock ||= {}
lock.each_key do |name|
  info[:dependencies] << "? #{name}"
end

dirname = [info[:name], info[:version]].join('_')
FileUtils.mkdir_p dirname

info = JSON.pretty_generate(info)
File.open(File.join(dirname, 'info.json'), 'w') { |f| f.puts info }

FileUtils.cp_r 'locale', dirname
