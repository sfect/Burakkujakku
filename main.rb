# encoding: utf-8
require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_AMOUNT = 17
INITIAL_POT_AMOUNT = 500

helpers do
  def calculate_total(cards)
    arr = cards.map{ |element| element[1] }

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    arr.select{ |element| element == "A" }.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end

    total
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] + session[:player_bet]
    @winner = "<strong>やりました！#{session[:player_name]}様の勝ちです！</strong>#{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] - session[:player_bet]
    @loser = "<strong>あ、これはあかんやつや。#{session[:player_name]}様の負けです！はい解散！#{msg}"
  end

  def tie!(msg)
    @play_again = true
    @winner = "<strong>おっとこれは引き分けです。いい勝負ですね。手に汗握りますね。#{msg}"
    @show_hit_or_stay_buttons = false
  end

end

before do
  @show_hit_or_stay_buttons = true
end


get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  session[:player_pot] = INITIAL_POT_AMOUNT
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "名前を入力してくださいッ！"
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do
  session[:player_bet] = nil
  erb :bet
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "お金を賭けてくださいッ！"
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "手持ちが#{session[:player_pot]}円しかありません！"
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end

get '/game' do 
  session[:turn] = session[:player_name]

  suits = ['H', 'D', 'S', 'C']
  values = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
  session[:deck] = suits.product(values).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []

  2.times do
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
  end

  erb :game  
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]}様、ブラックジャックです！") 
  elsif player_total > BLACKJACK_AMOUNT
    loser!("#{session[:player_name]}様、BUSTですwwwwwwwww")
  end
  erb :game, layout: false
end

post '/game/player/stay' do
  @success = "ステイしました。"
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("ディーラーがもう完全にブラックジャックです！！")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("ディーラーがBUSTしました。ディーラーの合計は#{dealer_total}でした。")
  elsif dealer_total >= DEALER_AMOUNT
    # dealer stays
    redirect '/game/compare'
  else
    # dealer hits
    @show_dealer_hit_button = true
  end

  erb :game, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect 'game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]}様の合計は#{player_total}、ディーラーの合計は#{dealer_total}でした。")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]}様の合計は#{player_total}、ディーラーの合計は#{dealer_total}でした。")
  else
    tie!("#{session[:player_name]}様とディーラーの二人とも合計は#{player_total}でした。")
  end
  erb :game
end

get '/game_over' do
  erb :game_over
end
