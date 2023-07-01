class FusionQuiz

  #
  # Possible difficulties:
  #
  # :REGULAR -> 4 options choice
  #
  # :ADVANCED -> List of all pokemon
  #
  def initialize(difficulty = :REGULAR)
    @sprites      = {}

    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @previewwindow=nil
    @difficulty = difficulty
    @customs_list = getCustomSpeciesList(true, false)
    @selected_pokemon = nil
    @head_id = nil
    @body_id = nil
    @choices = []

    @score = 0
  end

  def start_quiz(nb_rounds=3)
    round_multiplier = 1
    round_multiplier_increase = 0.1


    for i in 1..nb_rounds
      if i == nb_rounds
        pbMessage(_INTL("Get ready! Here comes the final round!"))
      elsif i ==1
        pbMessage(_INTL("Get ready! Here comes the first round!"))
      else
        pbMessage(_INTL("Get ready! Here comes round {1}!",i))
      end
      start_quiz_new_round(round_multiplier)


      rounds_left = nb_rounds-i
      if rounds_left >0
        pbMessage(_INTL("That's it for round {1}. You've accumulated {2} points so far.",i,@score))
        prompt_next_round = pbMessage(_INTL("Are you ready to move on to the next round?",i),["Yes","No"])
        if prompt_next_round != 0
          prompt_quit = pbMessage(_INTL("You still have {1} rounds to go. You'll only keep your points if you finish all {2} rounds. Do you really want to quit now?",rounds_left,nb_rounds),["Yes","No"])
          if prompt_quit
            pbMessage(_INTL("Well that's the show, folks. Make sure to tune in next time for some more Guess The Fusion!"))
            return
          end
        end
        round_multiplier += round_multiplier_increase
      else
        pbMessage(_INTL("That concludes our quiz! You've accumulated {1} points in total.",@score))
        pbMessage("Thanks for playing with us today!")
      end
    end


  end

  def start_quiz_new_round(round_multiplier=1)
    base_points_q1=300
    base_points_q1_redemption=100

    base_points_q2=400
    base_points_q2_redemption=100


    pick_random_pokemon()
    show_fusion_picture(true)
    correct_answers=[]

    #OBSCURED
    correct_answers << new_question(base_points_q1*round_multiplier, "Which Pokémon is this fusion's body?",@body_id,true,true )
    pbMessage("Next question!")
    correct_answers << new_question(base_points_q2*round_multiplier,"Which Pokémon is this fusion's head?", @head_id,true,true )
    @viewport.dispose

    show_fusion_picture(false )
    #NON-OBSCURED
    if !correct_answers[0] || !correct_answers[1]
      pbMessage("Okay, now's your chance to make up for the points you missed!")
      if !correct_answers[0] #1st question redemption
        new_question(base_points_q1_redemption, "Which Pokémon is this fusion's body?",@body_id,true,false )
        if !correct_answers[1]
          pbMessage("Next question!")
        end
      end

      if !correct_answers[1] #2nd question redemption
        new_question(base_points_q2_redemption,"Which Pokémon is this fusion's head?", @head_id,true,false )
      end
    else
      pbMessage("A perfect round! Here's what this Pokémon looked like!")
    end
    hide_fusion_picture()
    @viewport.dispose

  end


  def new_question(points_value,question, answer_id, should_generate_new_choices, other_chance_later)
    points_value=points_value.to_i
    answer_name = getPokemon(answer_id).real_name
    answered_correctly = give_answer(question,answer_id,should_generate_new_choices)
    award_points(points_value) if answered_correctly
    question_answer_followup_dialog(answered_correctly,answer_name,points_value,other_chance_later)
    return answered_correctly
  end



  def award_points(nb_points)
    @score += nb_points
  end

  def question_answer_followup_dialog(answered_correctly,correct_answer, points_awarded_if_win, other_chance_later=false)
    if !other_chance_later
      pbMessage("And the correct answer was...")
      pbMessage("...")
      pbMessage(_INTL("{1}!",correct_answer))
    end

    if answered_correctly
      pbMessage("That's a correct answer!")
      pbMessage(_INTL("You're awarded {1} points for your answer. Your current score is {2}",points_awarded_if_win,@score.to_s))
    else
      pbMessage("Unfortunately, that was a wong answer.")
      pbMessage("But you'll get another chance!") if other_chance_later
    end
  end


  def show_fusion_picture(obscured = false)
    hide_fusion_picture()
    picturePath = get_fusion_sprite_path(@head_id, @body_id)
    bitmap = AnimatedBitmap.new(picturePath)
    bitmap.scale_bitmap(Settings::FRONTSPRITE_SCALE)
    @previewwindow = PictureWindow.new(bitmap)
    @previewwindow.y = 30
    @previewwindow.x = 100
    @previewwindow.z = 100000
    if obscured
      @previewwindow.picture.pbSetColor(255, 255, 255, 200)
    end
  end

  def hide_fusion_picture()
    @previewwindow.dispose if @previewwindow
  end

  def pick_random_pokemon(save_in_variable = 1)
    random_pokemon = getRandomCustomFusionForIntro(true, @customs_list)
    @head_id = random_pokemon[0]
    @body_id = random_pokemon[1]
    @selected_pokemon = getSpeciesIdForFusion(@head_id, @body_id)
    pbSet(save_in_variable, @selected_pokemon)
  end

  def give_answer(prompt_message,answer_id,should_generate_new_choices)
    question_answered=false
    answer_pokemon_name = getPokemon(answer_id).real_name

    while !question_answered
      if @difficulty == :ADVANCED
        player_answer = prompt_pick_answer_advanced(prompt_message,answer_id)
      else
        player_answer = prompt_pick_answer_regular(prompt_message,answer_id,should_generate_new_choices)
      end
      confirmed = pbMessage("Is this your final answer?",["Yes","No"])
      if confirmed==0
        question_answered=true
      end
    end
    return player_answer == answer_pokemon_name
  end

  def get_random_pokemon_from_same_egg_group(pokemon,previous_choices)
    egg_groups = getPokemonEggGroups(pokemon)
    while true
      new_pokemon = rand(1,NB_POKEMON)+1
      new_pokemon_egg_groups = getPokemonEggGroups(new_pokemon)
      if (egg_groups & new_pokemon_egg_groups).any? && !previous_choices.include?(new_pokemon)
        return new_pokemon
      end
    end
  end

  def prompt_pick_answer_regular(prompt_message,real_answer,should_new_choices)
    commands = should_new_choices ? generate_new_choices(real_answer) : @choices
    chosen = pbMessage(prompt_message,commands)
    #chosen = pbChooseList(commands, 0, nil, 1)
    return commands[chosen]
  end

  def generate_new_choices(real_answer)
    choices = []
    choices << real_answer
    choices << get_random_pokemon_from_same_egg_group(real_answer,choices)
    choices << get_random_pokemon_from_same_egg_group(real_answer,choices)
    choices << get_random_pokemon_from_same_egg_group(real_answer,choices)

    commands = []
    choices.each do |dex_num, i|
      species = getPokemon(dex_num)
      commands.push(species.real_name)
    end
    @choices = commands
    return commands.shuffle
  end


  def prompt_pick_answer_advanced(prompt_message,answer)
    choices.each do |dex_num, i|
      species = getPokemon(dex_num)
      commands.push([i, species.real_name, species.real_name])
    end
    pbMessage(prompt_message)
    #chosen = pbChooseList(commands, 0, nil, 1)
  end

  def get_score
    return @score
  end

end
