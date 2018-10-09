require 'discordrb'
require 'json'

info = JSON.parse(File.read('info.json'))

bot = Discordrb::Commands::CommandBot.new(token: info['token'], client_id: info['client_id'], prefix: '$')
songs = Dir["songs/*.mp3"]

bot.command(:who_are_you?) do |event|
  event.respond "I'm Kilroy!"
end

bot.command(:play_song) do |event|
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