#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

GENERATE_NUMBER() {
    SECRET_NUMBER=$((RANDOM % 1000 + 1)) 
    echo Secret number is $SECRET_NUMBER
}

START_GAME() {

    GENERATE_NUMBER

    PLAYERS_BEST_GAME=null
    TOTAL_GAMES_PLAYED=null
    CURRENT_GUESS=null
    GUESS_COUNT=0
    GUESSED_CORRECTLY=false
    GUESS_IS_INTEGER=false

    echo Enter your username:
    read UNPROCESSED_USERNAME

    USERNAME="${UNPROCESSED_USERNAME,,}"

    #Check if it's a returning player
    RETURNING_PLAYER_CHECK

    #Request the first guess from the User
    echo "Guess the secret number between 1 and 1000:"
    read CURRENT_GUESS

    #Check if guess is correct
    CHECK_GUESS    
}

UPDATE_GAMES_PLAYED() {
  echo variable passed int UPDATE_GAMES_PLAYED: $1
  TOTAL_GAMES_PLAYED=$1 
}

RETURNING_PLAYER_CHECK() {
 #Does username exist in database?
  USER_EXISTS=$($PSQL "SELECT * FROM user_stats WHERE username='$USERNAME';")

  if [[ -z $USER_EXISTS ]]
    then
      #if user doesn't exist add them to the database
      IS_RETURNING_PLAYER=false #DO I need this?
      ADD_NEW_USER=$($PSQL "INSERT INTO user_stats(username) VALUES('$USERNAME'); ")
      GREET_NEW_PLAYER
    else     
      #Grab the current user's record from the database
      IS_RETURNING_PLAYER=true #DO I need this?
      echo "$USER_EXISTS" | while IFS="|" read -r USER_ID NAME GAMES_PLAYED BEST_GAME
        do
          UPDATE_GAMES_PLAYED $GAMES_PLAYED
          TOTAL_GAMES_PLAYED=$GAMES_PLAYED
          PLAYERS_BEST_GAME=$BEST_GAME
          echo while loop TOTAL_GAMES_PLAYED=$TOTAL_GAMES_PLAYED
          echo while loop PLAYERS_BEST_GAME=$TOTAL_BEST_GAME
          GREET_RETURNING_PLAYER
        done
      echo TOTAL_GAMES_PLAYED=$TOTAL_GAMES_PLAYED
      echo PLAYERS_BEST_GAME=$PLAYERS_BEST_GAME
  fi
 # echo current guess = $CURRENT_GUESS
}

GREET_RETURNING_PLAYER() {
      echo Welcome back, $USERNAME! You have played $TOTAL_GAMES_PLAYED games, and your best game took $PLAYERS_BEST_GAME guesses.
}

GREET_NEW_PLAYER() {
      echo Welcome, $USERNAME! It looks like this is your first time here.
}

IS_INTEGER?() {
  GUESS_IS_INTEGER=false
  while [[ !$GUESS_IS_INTEGER ]]
    do
      #Determine if the guess is an integer
      if [[ "$CURRENT_GUESS" =~ ^[0-9]+$ ]]; 
        then
          #It is an integer
          GUESS_IS_INTEGER=true
          ((GUESS_COUNT++))
          return 0
        else
          #It's not an integer
          echo That is not an integer, guess again:
          read CURRENT_GUESS
        fi
    done
    # echo At IS_INTEGER? CURRENT_GUESS = $CURRENT_GUESS
}

IS_GUESS_CORRECT?() {
  #Check if the guess is correct
  if [[ $CURRENT_GUESS = $SECRET_NUMBER ]]
    then
      echo You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!
      #Check if the number of guesses beat their previous best
      IS_BEST_GAME?
      INCREMENT_GAMES_PLAYED
      return 0
    else
      return 1
  fi
}

CHECK_GUESS() {
  IS_INTEGER?

  IS_GUESS_CORRECT? #Do I need this? Don't I check it in the while loop?
    #echo At start of CHECK_GUESS CURRENT_GUESS = $CURRENT_GUESS and SECRET_NUMBER = $SECRET_NUMBER
  
  while ! IS_GUESS_CORRECT?
    do
      #Check if the Guess is too high or too low
      if [ $CURRENT_GUESS -gt $SECRET_NUMBER ]
        then
          echo "It's lower than that, guess again:"
          read CURRENT_GUESS
        else
          echo "It's higher than that, guess again:"
          read CURRENT_GUESS
      fi
      IS_INTEGER?
    done
   # echo At end of CHECK_GUESS CURRENT_GUESS = $CURRENT_GUESS
}

IS_BEST_GAME?() {
  echo best_game: $PLAYERS_BEST_GAME 
  echo guess count: $GUESS_COUNT
  if [ $PLAYERS_BEST_GAME > $GUESS_COUNT ] || [ -z $PLAYERS_BEST_GAME ]
    then
      #Store new best game in database
      ADD_NEW_BEST_GAME=$($PSQL "UPDATE user_stats SET best_game=$GUESS_COUNT WHERE username='$USERNAME';")
      echo Congrats on beating your old record!
    else
      #only here for testing purposes
      echo Not a new Best
  fi
}

INCREMENT_GAMES_PLAYED() {
  #Add one to the TOTAL_GAMES_PLAYED variable
  echo Total games at start of INCREMENT_GAMES_PLAYED: $TOTAL_GAMES_PLAYED
  ((TOTAL_GAMES_PLAYED++))
  echo Total Games now equals: $TOTAL_GAMES_PLAYED

  #Save the new games_played number to the database
  UPDATE_GAMES_PLAYED=$($PSQL "UPDATE user_stats SET games_played=$TOTAL_GAMES_PLAYED WHERE username='$USERNAME';")
  echo Update Games Played: $UPDATE_GAMES_PLAYED
}

START_GAME