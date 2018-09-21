require 'json'
require 'pry'

def merge_jsons(primary_json, new_json, email_map)
  # set dbg = true to have verbose output
  dbg = false
  pdata = JSON.parse File.read primary_json
  users = {}
  np = 0
  pdata.each_with_index do |user, index|
    login = user['login'].downcase
    email = user['email'].downcase
    users[[login, email]] = user
    users[login] = [] unless users.key?(login)
    users[login] << user
    users[email] = [] unless users.key?(email)
    users[email] << user
    np += 1
  end
  data = JSON.parse File.read new_json
  nusers = {}
  nn = 0
  e = l = le = n = 0
  a = s = lo = 0
  data.each_with_index do |user, index|
    login = user['login'].downcase
    email = user['email'].downcase
    pri_user = nil
    mode = nil
    commits = "#{user['commits']}"
    if users.key?([login, email])
      pri_user = users[[login, email]]
      mode = 'le'
      le += 1
    else
      if users.key?(login)
        pri_user = users[login].first
        mode = 'l '
        l += 1
      else
        if users.key?(email)
          pri_user = users[email].first
          mode = ' e'
          e += 1
        end
      end
    end
    if pri_user
      commits += ",#{pri_user['commits']}"
      if user['affiliation'] != pri_user['affiliation'] && pri_user['affiliation'] != '?' && pri_user['affiliation'] != '(Unknown)'
        puts "#{mode} Using primary affiliation '#{pri_user['affiliation']}' instead of new '#{user['affiliation']}' for #{login}/#{email}/#{commits}"
        user['affiliation'] = pri_user['affiliation']
        a += 1
      end
      if user['sex'] != pri_user['sex'] || user['sex_prob'] != pri_user['sex_prob']
        if (pri_user['sex'] != nil || pri_user['sex_prob'] != nil) && (user['sex'] == nil || user['sex_prob'] == nil)
          puts "#{mode} Using primary gender '#{pri_user['sex']}, #{pri_user['sex_prob']}' instead of new '#{user['sex']}, #{user['sex_prob']}' for #{login}/#{email}/#{commits}" if dbg
          user['sex'] = pri_user['sex']
          user['sex_prob'] = pri_user['sex_prob']
          s += 1
        end
      end
      if user['country_id'] != pri_user['country_id'] || user['tz'] != pri_user['tz']
        if (pri_user['country_id'] != nil || pri_user['tz'] != nil) && (user['country_id'] == nil || user['tz'] == nil)
          puts "#{mode} Using primary location '#{pri_user['country_id']}, #{pri_user['tz']}' instead of new '#{user['country_id']}, #{user['tz']}' for #{login}/#{email}/#{commits}" if dbg
          user['country_id'] = pri_user['country_id']
          user['tz'] = pri_user['tz']
          lo += 1
        end
      end
    else
      n += 1
    end
    nusers[[login, email]] = user
    nn += 1
  end
  p = 0
  pdata.each_with_index do |user, index|
    login = user['login'].downcase
    email = user['email'].downcase
    unless nusers.key?([login, email])
      nusers[[login, email]] = user
      p += 1
    end
  end
  users = nusers.values.sort_by { |u| [-u['commits'], u['login'], u['email']] }
  puts "Primary users #{np}, new users #{nn}, merge: le #{le}, l #{l}, e #{e}, n #{n}, p #{p}"
  puts "Overwrites aff #{a}, gender #{s}, location #{lo}"

  # Write JSON back
  pretty = JSON.pretty_generate users
  File.write json_file, new_json
end

if ARGV.size < 3
  puts "Missing arguments: github_users.old github_users.json cncf-config/email-map"
  exit(1)
end

merge_jsons(ARGV[0], ARGV[1], ARGV[2])