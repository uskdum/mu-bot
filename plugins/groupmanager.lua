-- data saved to data/moderation.json
do

  local function export_chat_link_cb(extra, success, result)
    local msg = extra.msg
    local data = extra.data
    if success == 0 then
      return send_large_msg(get_receiver(msg), 'Emkane Skahte Linke Jadid Dar In Grouh Nist.\nAslan Admini?.')
    end
    data[tostring(msg.to.id)]['link'] = result
    save_data(_config.moderation.data, data)
    return send_large_msg(get_receiver(msg),'Linke Jaid Baraye Grouhe '..msg.to.title..' ine:\n'..result)
  end

  local function set_group_photo(msg, success, result)
    local data = load_data(_config.moderation.data)
    if success then
      local file = 'data/photos/chat_photo_'..msg.to.id..'.jpg'
      print('File downloaded to:', result)
      os.rename(result, file)
      print('File moved to:', file)
      chat_set_photo (get_receiver(msg), file, ok_cb, false)
      data[tostring(msg.to.id)]['settings']['set_photo'] = file
      save_data(_config.moderation.data, data)
      data[tostring(msg.to.id)]['settings']['lock_photo'] = 'yes'
      save_data(_config.moderation.data, data)
      send_large_msg(get_receiver(msg), 'Aks Zakhire Shod', ok_cb, false)
    else
      print('Error downloading: '..msg.id)
      send_large_msg(get_receiver(msg), 'Failed, please try again!', ok_cb, false)
    end
  end

  local function get_description(msg, data)
    local about = data[tostring(msg.to.id)]['description']
    if not about then
      return 'NO Descript In Gouh ;)'
	  end
    return string.gsub(msg.to.print_name, '_', ' ')..':\n\n'..about
  end

  -- media handler. needed by group_photo_lock
  local function pre_process(msg)
    if not msg.text and msg.media then
      msg.text = '['..msg.media.type..']'
    end
    return msg
  end

  function run(msg, matches)

    if is_chat_msg(msg) then
      local data = load_data(_config.moderation.data)

      -- create a group
      if matches[1] == 'makegp' and matches[2] and is_mod(msg.from.id, msg.to.id) then
        create_group_chat (msg.from.print_name, matches[2], ok_cb, false)
	      return 'Grouhe '..string.gsub(matches[2], '_', ' ')..' Sakhte Shod Va Aknoun Vared Shodid.'
      -- add a group to be moderated
      elseif matches[1] == 'addgp' and is_admin(msg.from.id, msg.to.id) then
        if data[tostring(msg.to.id)] then
          return 'Grouh Add Shod!'
        end
        -- create data array in moderation.json
        data[tostring(msg.to.id)] = {
          moderators ={},
          settings = {
            set_name = string.gsub(msg.to.print_name, '_', ' '),
            lock_bots = 'no',
            lock_name = 'yes',
            lock_photo = 'no',
            lock_member = 'no',
            anti_flood = 'ban',
            welcome = 'group',
            sticker = 'ok',
            }
          }
        save_data(_config.moderation.data, data)
        return 'Grouh Add Shod!.'
      -- remove group from moderation
      elseif matches[1] == 'delgp' and is_admin(msg.from.id, msg.to.id) then
        if not data[tostring(msg.to.id)] then
          return 'Grouh add Nashode.'
        end
        data[tostring(msg.to.id)] = nil
        save_data(_config.moderation.data, data)
        return 'Grouh Az List Pak Shod'
      end

      if msg.media and is_chat_msg(msg) and is_mod(msg.from.id, msg.to.id) then
        if msg.media.type == 'aks' and data[tostring(msg.to.id)] then
          if data[tostring(msg.to.id)]['settings']['set_photo'] == 'waiting' then
            load_photo(msg.id, set_group_photo, msg)
          end
        end
      end

      if data[tostring(msg.to.id)] then

        local settings = data[tostring(msg.to.id)]['settings']

        if matches[1] == 'sdarbare' and matches[2] and is_mod(msg.from.id, msg.to.id) then
	        data[tostring(msg.to.id)]['description'] = matches[2]
	        save_data(_config.moderation.data, data)
	        return 'Set group descript to:\n'..matches[2]
        elseif matches[1] == 'darbare' then
          return get_description(msg, data)
        elseif matches[1] == 'sghavanin' and is_mod(msg.from.id, msg.to.id) then
	        data[tostring(msg.to.id)]['rules'] = matches[2]
	        save_data(_config.moderation.data, data)
	        return 'Set group ghanounha to:\n'..matches[2]
        elseif matches[1] == 'ghavanin' then
          if not data[tostring(msg.to.id)]['rules'] then
            return 'Hich Ghabouni Nadare!.'
	        end
          local rules = data[tostring(msg.to.id)]['rules']
          local rules = string.gsub(msg.to.print_name, '_', ' ')..' Ghavanin:\n\n'..rules
          return rules
        -- group link {get|set}
        elseif matches[1] == 'link' then
          if matches[2] == 'get' then
            if data[tostring(msg.to.id)]['link'] then
              local about = get_description(msg, data)
              local link = data[tostring(msg.to.id)]['link']
              return about..'\n\n'..link
            else
              return 'Linki Vojoud Nadare.\nEmtehan kon Dastour--> !link ta Link Sabt She.'
            end
          elseif matches[2] == 'set' and is_mod(msg.from.id, msg.to.id) then
            msgr = export_chat_link(get_receiver(msg), export_chat_link_cb, {data=data, msg=msg})
          end
	      elseif matches[1] == 'gp' then
          -- lock {bot|name|member|photo|sticker}
          if matches[2] == 'ghofle' then
            if matches[3] == 'robat' and is_mod(msg.from.id, msg.to.id) then
	            if settings.lock_bots == 'yes' then
                return 'Az Ghabl Ghofl Boud.'
	            else
                settings.lock_bots = 'yes'
                save_data(_config.moderation.data, data)
                return 'Ghofl Shod.BB Bots.'
	            end
            elseif matches[3] == 'esm' and is_mod(msg.from.id, msg.to.id) then
	            if settings.lock_name == 'yes' then
                return 'Az Ghabl Ghofl Boud'
	            else
                settings.lock_name = 'yes'
                save_data(_config.moderation.data, data)
                settings.set_name = string.gsub(msg.to.print_name, '_', ' ')
                save_data(_config.moderation.data, data)
	              return 'Esm Ghoflid.Khaye dari Esmo Avaz Kon!'
	            end
            elseif matches[3] == 'ozv' and is_mod(msg.from.id, msg.to.id) then
	            if settings.lock_member == 'yes' then
                return 'Az Ghabl Boud'
	            else
                settings.lock_member = 'yes'
                save_data(_config.moderation.data, data)
	            end
	            return 'Kasi Dg Nemiad Natars!'
            elseif matches[3] == 'aks' and is_mod(msg.from.id, msg.to.id) then
	            if settings.lock_photo == 'yes' then
                return 'Az Ghabl Boud'
	            else
                settings.set_photo = 'waiting'
                save_data(_config.moderation.data, data)
	            end
              return 'Akso Bede'
            end
          -- unlock {bot|name|member|photo|sticker}
		      elseif matches[2] == 'unghofle' then
            if matches[3] == 'robat' and is_mod(msg.from.id, msg.to.id) then
	            if settings.lock_bots == 'no' then
                return 'Az Ghabl Boud!'
	            else
                settings.lock_bots = 'no'
                save_data(_config.moderation.data, data)
                return 'Robat Ha mitunan Bian.'
	            end
            elseif matches[3] == 'esm' and is_mod(msg.from.id, msg.to.id) then
	            if settings.lock_name == 'no' then
                return 'Az Ghabl Boud!'
	            else
                settings.lock_name = 'no'
                save_data(_config.moderation.data, data)
                return 'Taghire Esm Emkan Pazire!'
	            end
            elseif matches[3] == 'ozv' and is_mod(msg.from.id, msg.to.id) then
	            if settings.lock_member == 'no' then
                return 'Ghofl Naboud!'
	            else
                settings.lock_member = 'no'
                save_data(_config.moderation.data, data)
                return 'Ghofle Ozvha Baz Shod Vared Shavid!'
	            end
            elseif matches[3] == 'aks' and is_mod(msg.from.id, msg.to.id) then
	            if settings.lock_photo == 'no' then
                return 'Ghofl Naboud'
	            else
                settings.lock_photo = 'no'
                save_data(_config.moderation.data, data)
                return 'GhoflShod.Akso Nemitunan Taghir BEdan'
	            end
            end
          -- view group settings
          elseif matches[2] == 'settings' and is_mod(msg.from.id, msg.to.id) then
            if settings.lock_bots == 'yes' then
              lock_bots_state = '🔒'
            elseif settings.lock_bots == 'no' then
              lock_bots_state = '🔓'
            end
            if settings.lock_name == 'yes' then
              lock_name_state = '🔒'
            elseif settings.lock_name == 'no' then
              lock_name_state = '🔓'
            end
            if settings.lock_photo == 'yes' then
              lock_photo_state = '🔒'
            elseif settings.lock_photo == 'no' then
              lock_photo_state = '🔓'
            end
            if settings.lock_member == 'yes' then
              lock_member_state = '🔒'
            elseif settings.lock_member == 'no' then
              lock_member_state = '🔓'
            end
            if settings.anti_flood ~= 'no' then
              antispam_state = '🔒'
            elseif settings.anti_flood == 'no' then
              antispam_state = '🔓'
            end
            if settings.welcome ~= 'no' then
              greeting_state = '🔒'
            elseif settings.welcome == 'no' then
              greeting_state = '🔓'
            end
            if settings.sticker ~= 'ok' then
              sticker_state = '🔒'
            elseif settings.sticker == 'ok' then
              sticker_state = '🔓'
            end
            local text = 'Tanzimate Gorouh:\n'
                  ..'\n'..lock_bots_state..' Ghofle Robatha az Gp : '..settings.lock_bots
                  ..'\n'..lock_name_state..' Ghofle Esme Gp : '..settings.lock_name
                  ..'\n'..lock_photo_state..' Ghofle Akse Gp : '..settings.lock_photo
                  ..'\n'..lock_member_state..' Ghofle Ozve Gp : '..settings.lock_member
                  ..'\n'..antispam_state..' Mohafeze Zer Zadan : '..settings.anti_flood
                  ..'\n'..sticker_state..' Sticker policy : '..settings.sticker
                  ..'\n'..greeting_state..' Payame Welcome : '..settings.welcome
            return text
		      end
        elseif matches[1] == 'sticker' then
          if matches[2] == 'warn' then
            if settings.sticker ~= 'warn' then
              settings.sticker = 'warn'
              save_data(_config.moderation.data, data)
            end
            return 'Ghofle Sticker.\n'
                   ..'Bare Avval Ekhtar Bare Dovom Sik :)'
          elseif matches[2] == 'sik' then
            if settings.sticker ~= 'sik' then
              settings.sticker = 'sik'
              save_data(_config.moderation.data, data)
            end
            return 'Ghofle Sticker.\nBefresti Siki'
          elseif matches[2] == 'ok' then
            if settings.sticker == 'ok' then
              return 'Ghofle Sticker Faal Nist'
            else
              settings.sticker = 'ok'
              save_data(_config.moderation.data, data)
              return 'Ghfole Sticker Gheyre Faal Shod'
            end
          end
        -- if group name is renamed
        elseif matches[1] == 'chat_rename' then
          if not msg.service then
            return 'Are you trying to troll me?'
          end
          if settings.lock_name == 'yes' then
            if settings.set_name ~= tostring(msg.to.print_name) then
              rename_chat(get_receiver(msg), settings.set_name, ok_cb, false)
            end
          elseif settings.lock_name == 'no' then
            return nil
          end
		    -- set group name
		    elseif matches[1] == 'setesm' and is_mod(msg.from.id, msg.to.id) then
          settings.set_name = string.gsub(matches[2], '_', ' ')
          save_data(_config.moderation.data, data)
          rename_chat(get_receiver(msg), settings.set_name, ok_cb, false)
		    -- set group photo
		    elseif matches[1] == 'setaks' and is_mod(msg.from.id, msg.to.id) then
          settings.set_photo = 'waiting'
          save_data(_config.moderation.data, data)
          return 'Akso Bede...'
        -- if a user is added to group
		    elseif matches[1] == 'chat_add_user' then
          if not msg.service then
            return 'Are you trying to troll me?'
          end
          local user = 'user#id'..msg.action.user.id
          if settings.lock_member == 'yes' then
            chat_del_user(get_receiver(msg), user, ok_cb, true)
          -- no APIs bot are allowed to enter chat group, except invited by mods.
          elseif settings.lock_bots == 'yes' and msg.action.user.flags == 4352 and not is_mod(msg.from.id, msg.to.id) then
            chat_del_user(get_receiver(msg), user, ok_cb, true)
          elseif settings.lock_bots == 'no' or settings.lock_member == 'no' then
            return nil
          end
        -- if sticker is sent
        elseif msg.media and msg.media.caption == 'sticker.webp' and not is_sudo(msg.from.id) then
          local user_id = msg.from.id
          local chat_id = msg.to.id
          local sticker_hash = 'mer_sticker:'..chat_id..':'..user_id
          local is_sticker_offender = redis:get(sticker_hash)
          if settings.sticker == 'warn' then
            if is_sticker_offender then
              chat_del_user(get_receiver(msg), 'user#id'..user_id, ok_cb, true)
              redis:del(sticker_hash)
              return 'To Nabayad Sticker Berfresti Too In Gorouh'
            elseif not is_sticker_offender then
              redis:set(sticker_hash, true)
              return 'Inja Sticker Nafrest!\nEkhtare Avval, Dafe Bad Sik!'
            end
          elseif settings.sticker == 'sik' then
            chat_del_user(get_receiver(msg), 'user#id'..user_id, ok_cb, true)
            return 'Sticker Nafres'
          elseif settings.sticker == 'ok' then
            return nil
          end
        -- if group photo is deleted
		    elseif matches[1] == 'chat_delete_photo' then
          if not msg.service then
            return 'Are you trying to troll me?'
          end
          if settings.lock_photo == 'yes' then
            chat_set_photo (get_receiver(msg), settings.set_photo, ok_cb, false)
          elseif settings.lock_photo == 'no' then
            return nil
          end
		    -- if group photo is changed
		    elseif matches[1] == 'chat_change_photo' and msg.from.id ~= 0 then
          if not msg.service then
            return 'Are you trying to troll me?'
          end
          if settings.lock_photo == 'yes' then
            chat_set_photo (get_receiver(msg), settings.set_photo, ok_cb, false)
          elseif settings.lock_photo == 'no' then
            return nil
          end
        end
      end
    else
      print '>>> This is not a chat group.'
    end
  end

  return {
    description = 'Plugin to manage group chat.',
    usage = {
      admin = {
        '^[/!@#$%?][Mm]akegp <group_name> : Make/create a new group.',
        '^[/!@#$%?][Aa]ddgp : Add group to moderation list.',
        '^[/!@#$%?][Dd]elgp : Remove group from moderation list.',
        '^([Mm]akegp (.*)$',
        '^([Aa]ddgp)$',
        '^([Dd]elgp)$'
      },
      moderator = {
        '^[/!@#$%?][Gg]p <ghofle|unghofle> robat : {Dis}allow APIs bots.',
        '^[/!@#$%?][Gg]p <ghofle|unghofle> ozv : Lock/unlock group member.',
        '^[/!@#$%?][Gg]p <ghofle|unghofle> esm : Lock/unlock group name.',
        '^[/!@#$%?][Gg]p <ghofle|unghofle> aks : Lock/unlock group photo.',
        '^[/!@#$%?][Gg]p settings : Show group settings.',
        '^[/!@#$%?][Ll]ink <set> : Generate/revoke invite link.',
        '^[/!@#$%?][Ss]darbare <description> : Set group description.',
        '^[/!@#$%?][Ss]etesm <new_name> : Set group name.',
        '^[/!@#$%?][Ss]etaks : Set group photo.',
        '^[/!@#$%?][Ss]ghavanin <rules> : Set group rules.',
        '^[/!@#$%?][Ss]ticker warn : Sticker restriction, sender will be warned for the first violation.',
        '^[/!@#$%?][Ss]ticker kick : Sticker restriction, sender will be kick.',
        '^[/!@#$%?][Ss]ticker ok : Disable sticker restriction.',
        '^([Gg]p) (ghofle) (.*)$',
        '^([Gg]p) (settings)$',
        '^([Gg]p) (unghofle) (.*)$',
        '^([Gg]p) (.*)$',
        '^([Ss]darbare) (.*)$',
        '^([Ss]etesm) (.*)$',
        '^([Ss]etaks)$',
        '^([Ss]ghavanin) (.*)$',
        '^([Ss]ticker) (.*)$'
      },
      user = {
        '^[/!@#$%?][Dd]arbare : Read group description',
        '^[/!@#$%?][Gg]havanin : Read group rules',
        '^[/!@#$%?][Ll]ink <get> : Print invite link',
        '^([Dd]arbare)$',
        '^([Gg]havanin)$'
      },
    },
    patterns = {
      '^[/!@#$%?]([Dd]arbare)$',
      '^[/!@#$%?]([Aa]ddgp)$',
      '%[(audio)%]',
      '%[(document)%]',
      '^[/!@#$%?]([Gg]p) (ghofle) (.*)$',
      '^[/!@#$%?](Gg]p) (settings)$',
      '^[/!@#$%?](Gg]p) (unghofle) (.*)$',
      '^[/!@#$%?](Gg]p) (.*)$',
      '^[/!@#$%?]([Mm]akegp) (.*)$',
      '%[(photo)%]',
      '^[/!@#$%?]([Dd]elgp)$',
      '^[/!@#$%?]([Gg]havanin)$',
      '^[/!@#$%?]([Ss]darbare) (.*)$',
      '^[/!@#$%?]([Ss]etesm) (.*)$',
      '^[/!@#$%?]([Ss]etaks)$',
      '^[/!@#$%?]([Ss]ghavanin) (.*)$',
      '^[/!@#$%?]([Ss]ticker) (.*)$',
      '^!!tgservice (.+)$',
      '%[(video)%]'
    },
    run = run,
    pre_process = pre_process
  }

end
