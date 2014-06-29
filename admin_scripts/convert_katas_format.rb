#!/usr/bin/env ruby

# Script to convert katas in old .rb format into new
# katas (with new id) in new .json format

def my_dir
  File.dirname(__FILE__)
end

require my_dir + '/lib_domain'

#- - - - - - - - - - - - - - - - - - - - - - - -

def root_dir
  File.expand_path('..', my_dir)
end

#- - - - - - - - - - - - - - - - - - - - - - - -

def make_time(now)
  [now.year, now.month, now.day, now.hour, now.min, now.sec]
end

#- - - - - - - - - - - - - - - - - - - - - - - -

def calc_delta(was,now)
  result = {
    :unchanged => [ ],
    :changed   => [ ],
    :deleted   => [ ]
  }

  was.each do |filename,content|
    if now[filename] == content
      result[:unchanged] << filename
    elsif now[filename] != nil
      result[:changed] << filename
    else
      result[:deleted] << filename
    end
    now.delete(filename)
  end

  result[:new] = now.keys
  result
end

#- - - - - - - - - - - - - - - - - - - - - - - -

def replay_rb_as_json(dojo,sid,dot_count)
  s = dojo.katas[sid]
  outer = sid[0..1]
  inner = sid[2..-1]
  raw = s.dir.read('manifest.rb')
  raw = raw.force_encoding('UTF-8')
  text = raw.encode('UTF-8', 'binary', :invalid => :replace, :undef => :replace, :replace => '')
  manifest = eval(text)

  tid = outer + '1'*8
  t = dojo.katas.create_kata(s.language, s.exercise, tid, make_time(s.created))
  t.dir.write('manifest.json', JSON.unparse(manifest))

  s.avatars.each do |avatar|
    tavatar = t.start_avatar([avatar.name])
    prev_visible_files = avatar.visible_files(0)
    max_tag = `cd #{avatar.path};git shortlog`.lines.entries[-2].strip.to_i

    puts "\n#{sid}:#{avatar.name}:#{max_tag}    (#{dot_count})"

     (1..max_tag).each do |tag|
      #puts "\t#{tag}:avatar.traffic_lights(tag)"
      lights = avatar.traffic_lights(tag)
      last = lights.last
      now = last['time']

      #puts "\t#{tag}:tavatar.save_traffic_light(last,now)"
      tavatar.save_traffic_light(last,now)

      #puts "\t#{tag}:avatar.visible_files(tag)"
      curr_visible_files = avatar.visible_files(tag)

      delta = calc_delta(prev_visible_files.clone, curr_visible_files.clone)

      #puts "\t#{tag}:tavatar.save(delta,curr_visible_files)"
      tavatar.save(delta, curr_visible_files)

      #puts "\t#{tag}:tavatar.save_manifest(curr_visible_files)"
      tavatar.save_manifest(curr_visible_files)

      #puts "\t#{tag}:tavatar.commit(tag)"
      tavatar.commit(tag)

      prev_visible_files = curr_visible_files
    end
  end

  # mv katas/0A/998360EA to katas_rb/0A/998360EA
  mkdir_cmd = "mkdir -p #{root_dir}/katas_rb/#{outer}"
  `#{mkdir_cmd}`
  mv_cmd = "mv #{root_dir}/katas/#{outer}/#{inner} #{root_dir}/katas_rb/#{outer}/#{inner}"
  `#{mv_cmd}`

  # rename dir 0A/11111111 to 0A/998360EA
  rename_cmd = "mv #{root_dir}/katas/#{outer}/#{'1'*8} #{root_dir}/katas/#{outer}/#{inner}"
  `#{rename_cmd}`

end

#- - - - - - - - - - - - - - - - - - - - - - - - -

puts
dot_count = 0
dojo = create_dojo
dojo.katas.each do |kata|
  if kata.format === 'rb'
    begin
      replay_rb_as_json(dojo,kata.id.to_s,dot_count)
      #puts kata.id.to_s
      #break
    rescue SyntaxError => error
      puts "\nSyntaxError from kata #{kata.id}"
      puts error.message
      outer = kata.id.to_s[0..1]
      inner = kata.id.to_s[2..-1]
      mkdir_cmd = "mkdir -p #{root_dir}/katas_rb_bad/#{outer}"
      `#{mkdir_cmd}`
      mv_cmd = "mv #{root_dir}/katas/#{outer}/#{inner} #{root_dir}/katas_rb_bad/#{outer}/#{inner}"
      `#{mv_cmd}`
      exit
    rescue Encoding::InvalidByteSequenceError => error
      puts "\nEncoding::InvalidByteSequenceError from kata #{kata.id}"
      puts error.message
      outer = kata.id.to_s[0..1]
      inner = kata.id.to_s[2..-1]
      mkdir_cmd = "mkdir -p #{root_dir}/katas_rb_bad/#{outer}"
      `#{mkdir_cmd}`
      mv_cmd = "mv #{root_dir}/katas/#{outer}/#{inner} #{root_dir}/katas_rb_bad/#{outer}/#{inner}"
      `#{mv_cmd}`
      exit
    rescue ArgumentError => error
      puts "\nArgumentError from kata #{kata.id}"
      puts error.message
      outer = kata.id.to_s[0..1]
      inner = kata.id.to_s[2..-1]
      mkdir_cmd = "mkdir -p #{root_dir}/katas_rb_bad/#{outer}"
      `#{mkdir_cmd}`
      mv_cmd = "mv #{root_dir}/katas/#{outer}/#{inner} #{root_dir}/katas_rb_bad/#{outer}/#{inner}"
      `#{mv_cmd}`
      exit
    rescue NoMethodError => error
      puts "\nNoMethodError from kata #{kata.id}"
      puts error.message
      outer = kata.id.to_s[0..1]
      inner = kata.id.to_s[2..-1]
      mkdir_cmd = "mkdir -p #{root_dir}/katas_rb_bad/#{outer}"
      `#{mkdir_cmd}`
      mv_cmd = "mv #{root_dir}/katas/#{outer}/#{inner} #{root_dir}/katas_rb_bad/#{outer}/#{inner}"
      `#{mv_cmd}`
      exit
    end
  end
  dot_count += 1
end
puts
puts
