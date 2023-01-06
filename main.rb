require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'json'
require 'sinatra'
require 'linguistics'

Linguistics.use(:en)
class WordMaker
  attr_accessor :nouns, :adjectives, :verbs, :genres, :random

  def initialize(seed = nil)
    file = File.read('./sample.json')
    genre_file = File.read('./game-genres.json')
    data_hash = JSON.parse(file)
    genre_hash = JSON.parse(genre_file)
    @random = if seed
                Random.new(seed.to_i)
              else
                Random.new
              end

    @genres = {}
    @nouns = {}
    @adjectives = {}
    @verbs = {}
    data_hash.each do |word, meta|
      noun_def = meta.dig('definitions')&.filter { |d| d['partOfSpeech'] == 'noun' }&.first&.dig('definition')
      noun_type = meta.dig('definitions')&.filter { |d| d['partOfSpeech'] == 'noun' }&.first&.dig('typeOf')
      adjective_def = meta.dig('definitions')&.filter { |d| d['partOfSpeech'] == 'adjective' }&.first&.dig('definition')
      verb_def = meta.dig('definitions')&.filter { |d| d['partOfSpeech'] == 'verb' }&.first&.dig('definition')
      verb_type = meta.dig('definitions')&.filter { |d| d['partOfSpeech'] == 'verb' }&.first&.dig('typeOf')
      verb_category = meta.dig('definitions')&.filter { |d| d['partOfSpeech'] == 'verb' }&.first&.dig('inCategory')
      @nouns[word] = { noun_def:, noun_type: } unless noun_def.nil?
      @verbs[word] = { verb_def:, verb_type:, verb_category: } unless verb_def.nil?
      @adjectives[word] = adjective_def unless adjective_def.nil?
    end

    genre_hash.each do |name, genre|
      @genres[name] = genre
    end
  end

  def generate_prompt(adjective_count = 2, noun_count = 2, verb_count = 1)
    random_nouns = @nouns.to_a.sample(noun_count, random: @random)
    random_adjectives = @adjectives.to_a.sample(adjective_count, random: @random)
    random_verbs = @verbs.to_a.sample(verb_count, random: @random)
    # puts "#{random_adjectives.first[0]} #{random_nouns.first[0]} #{random_verbs.first[0]}"
    random_verb = random_verbs.first
    verb = random_verb[0]
    random_noun = random_nouns.first
    noun = random_noun[0]
    random_adjective = random_adjectives.first
    adjective = random_adjective[0]
    # puts "fullnoun: #{random_nouns.first}"
    # puts "noun: #{noun}"
    # puts "fulladj: #{random_adjectives.first}"
    # puts "adj: #{adjective}"
    # puts "fullverb: #{random_verbs.first}"
    # puts "verb: #{verb}"
    # puts Verbs::Conjugator.conjugate verb, person: :first, aspect: :habitual, subject: "#{adjective} #{noun}"
    # puts Verbs::Conjugator.conjugate verb, person: :first, aspect: :perfect, subject: "#{adjective} #{noun}"
    # puts Verbs::Conjugator.conjugate verb, person: :first, aspect: :perfective, subject: "#{adjective} #{noun}"
    # puts Verbs::Conjugator.conjugate verb, person: :first, aspect: :progressive, subject: "#{adjective} #{noun}"
    # puts Verbs::Conjugator.conjugate verb, person: :first, aspect: :prospective, subject: "#{adjective} #{noun}"
    # puts Verbs::Conjugator.conjugate verb, person: :second, aspect: :progressive, mood: :imperative,
    #                                        subject: "#{adjective} #{noun}"
    # puts Verbs::Conjugator.conjugate verb, person: :first, aspect: :progressive, mood: :subjunctive,
    #                                        subject: "#{adjective} #{noun}"
    # "#{adjective} #{noun} that can #{verb}"
    { noun:, noun_def: random_noun[1][:noun_def], adj: adjective, adj_def: random_adjective[1], verb:,
      verb_def: random_verb[1][:verb_def] }
  end

  def generate_genre
    random_genre = @genres['Genre'].sample(1, random: @random).first
    random_subgenre = random_genre['subgenres'].sample(1, random: @random).first
    "#{random_genre['name']} - #{random_subgenre}"
  end

  # 93288931694174127385818610690008931196
  def generate_game_idea
    prompt = generate_prompt

    prompt_text = "#{prompt[:adj]} #{prompt[:noun]} that can #{prompt[:verb]}"
    # retval = "A #{generate_genre} game about a #{prompt_text}\n\n"
    # retval << "Definitions \n- Noun: #{prompt[:noun_def]}\n- Adjective: #{prompt[:adj_def]}]\n- Verb: #{prompt[:verb_def]}"
    # retval
    {
      genre: generate_genre,
      prompt_text:,
      noun: prompt[:noun],
      adj: prompt[:adj],
      verb: prompt[:verb],
      defs: {
        noun_def: prompt[:noun_def],
        adjective_def: prompt[:adj_def],
        verb_def: prompt[:verb_def]
      }
    }
  end
end

get '/' do
  w = WordMaker.new(params['seed'])
  @prompt = w.generate_game_idea
  @prompt_noun = @prompt[:noun]
  @prompt_adj = @prompt[:adj]
  @prompt_verb = @prompt[:verb]
  prompt_title_first, *prompt_title_rest = @prompt[:genre].split(' ')
  prompt_text_first, *prompt_text_rest = @prompt[:prompt_text].split(' ')
  @prompt_title = "#{prompt_title_first.en.an} #{prompt_title_rest.join(' ')}"
  @prompt_text = "#{prompt_text_first.en.an} #{prompt_text_rest.join(' ')}"
  @prompt_title << ' game' unless prompt_text_rest.last.include? 'game'
  @seed = w.random.seed
  @host = "#{request.scheme}://#{request.host}"
  @host += ":#{request.port}" unless request.port.nil?
  puts @seed
  erb :index, locals: { prompt: @prompt }
end
