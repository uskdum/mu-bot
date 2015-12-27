do

  function run(msg, matches)
    return 'No Fuzuli!!\nNo Fuzuli!!'
  end

  return {
    description = 'Shows bot version',
    usage = '[/!@#$%?]version: Shows bot version',
    patterns = {
      '^[/!@#$%?]version$'
    },
    run = run
  }

end
