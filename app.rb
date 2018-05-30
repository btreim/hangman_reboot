
require "sinatra"
# require 'yaml'
if development?
  require "sinatra/reloader"
end
require_relative './lib/hangman_array.rb'

dictionary = []
f = File.read("5desk.txt")
f.each_line {|word| dictionary << word.chomp.downcase if word.chomp.length.between?(5,9)}


get '/' do
  erb :index, layout: :main
end

get '/win' do
  erb :win, layout: :main
end

get '/lose' do
  solution = @@h.solution.join("")
  erb :lose, layout: :main, :locals => {:solution => solution}
end

get '/new' do
  @@h = Hangman.new(dictionary)
  @@h.generate_new_game
  erb :guess, layout: :main
end

post '/guess' do
  guess = params["guess"]
  @@h.game_loop(guess)
  win_lose(@@h)
  erb :guess, layout: :main
end


def win_lose(h)
  redirect '/win' if h.win
  redirect '/lose' if h.win == false
end



class Hangman
  attr_accessor :id, :solution, :correct_guess, :all_guess, :win, :incorrect

  def initialize(dictionary)
    @dictionary = dictionary
  end

  def clean_input
    input = ""
    until input.match(/^[a-z]$/)
      print "Please type one letter from A to Z - or - 'save': "
      input = gets.chomp.downcase
      if input == "save"
        save_file
      end
    end
    input
  end

  def generate_new_game
    self.win = nil
    self.id = nil
    self.solution = random_word.split("")
    self.correct_guess = Array.new(self.solution.length, "-")
    self.all_guess = Array.new
    self.incorrect = 0
  end

  def save_file
    if self.id == nil
      puts "Please name your file"
      print "Filename:"
      self.id = gets.downcase.chomp
    end

    f = "./saved/#{id}.yaml"
    File.open(f, 'w+') { |file| file.write(self.to_yaml)}

    puts "...\n#{id} saved!\n..."
  end

  def display_saved_games
    files =[]
    input = ""

    Dir.glob("saved/*") { |file| files << file }
    puts "Please select a file: "
    files.each_with_index do |file, index|
      puts "(#{index})#{file[/\/\w*/]}\n"
    end

    until input.match(/\d/)
      input = gets.chomp.downcase
    end
    files[input.to_i]
  end

  def load_file(file_choice)
    selected = File.open(file_choice, 'r')
    file = YAML::load(selected)
    self.win = file.win
    self.id = file.id
    self.solution = file.solution
    self.correct_guess = file.correct_guess
    self.all_guess = file.all_guess
    self.incorrect = file.incorrect
    check_win_lose
    game_loop
  end

  def random_word
    max_length = @dictionary.length
    index = rand(0..max_length)
    @dictionary[index]
  end

  def check_if_correct(guess)
    solution.each_with_index do |letter, index|
      if letter == guess
        correct_guess[index] = guess
      end
    end
    if solution.include?(guess) == false
      puts "That was incorrect! "
      self.incorrect += 1
    end
  end

  def check_win_lose(*guess)
    if correct_guess == solution
      self.win = true
    elsif incorrect == 6
      self.win = false
      draw_hangman(incorrect)
    end

    draw_hangman(incorrect)
    puts "Solution: #{correct_guess.join}"
  end

  def draw_hangman(num_incorrect)
    puts $hangman[num_incorrect]
  end

  def game_loop(guess)
    check_if_correct(guess)
    all_guess << guess
    check_win_lose(guess)
  end
end
