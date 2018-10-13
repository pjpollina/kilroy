require 'discordrb'
require 'json'

keys = JSON.parse(File.read('data/keys.json'))
commands = JSON.parse(File.read('data/commands.json'))

bot = Discordrb::Commands::CommandBot.new(token: keys['token'], client_id: keys['client_id'], prefix: '$')
songs = Dir["songs/*.mp3"]

bot.bucket :radio, limit: 1, time_span: 120

bot.command(:help) do |event|
  event.respond "Kilroy commands:"
  commands.each do |key, value|
    event.respond "\t- #{key}: #{value}"
  end
end

bot.command(:who_are_you?) do |event|
  event.respond "I'm Kilroy!"
end

bot.command(:play_song, bucket: :radio) do |event|
   channel = event.user.voice_channel
   unless channel
      event.respond "No way fuckboy." 
      next
   end

   bot.voice_connect(channel)

   song = songs.sample
   event.respond "Now playing #{song[6...-4]}"
   audio = event.voice
   audio.play_file(song)
end

bot.run