#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

START_GAME() {
  echo "Enter your username:"
  read NAME
  n=${#NAME}

  if [[ ! $n -le 22 ]] || [[ ! $n -gt 0 ]]
  then
    START_GAME
  else
    USER_NAME=$(echo $($PSQL "SELECT username FROM users WHERE username='$NAME';") | sed 's/ //g')
    if [[ ! -z $USER_NAME ]]
    then
      USER_ID=$(echo $($PSQL "SELECT user_id FROM users WHERE username='$USER_NAME';") | sed 's/ //g')
      USER_NAME=$(echo $($PSQL "SELECT username FROM users WHERE user_id='$USER_ID';") | sed 's/ //g')
      GAME_PLAYED=$(echo $($PSQL "SELECT frequent_games FROM users WHERE user_id=$USER_ID;") | sed 's/ //g')
      BEST_GAME=$(echo $($PSQL "SELECT MIN(best_guess) FROM users LEFT JOIN games USING(user_id) WHERE user_id=$USER_ID;") | sed 's/ //g')
      echo "Welcome back, $USER_NAME! You have played $GAME_PLAYED games, and your best game took $BEST_GAME guesses."
    else
      USER_NAME=$NAME
      echo -e "\nWelcome, $USER_NAME! It looks like this is your first time here."
    fi

    CORRECT_ANSWER=$(( $RANDOM % 1000 + 1 ))
    GUESS_COUNT=0
    GUESSED_INPUT $USER_NAME $CORRECT_ANSWER $GUESS_COUNT
  fi
}

GUESSED_INPUT() {
  USER_NAME=$1
  CORRECT_ANSWER=$2
  GUESS_COUNT=$3
  USER_GUESS=$4

  if [[ -z $USER_GUESS ]]
  then
    echo "Guess the secret number between 1 and 1000:"
    read USER_GUESS
  else
    echo "That is not an integer, guess again:"
    read USER_GUESS
  fi

  GUESS_COUNT=$(( $GUESS_COUNT + 1 ))
  if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]
  then
    GUESSED_INPUT $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USER_GUESS
  else
    GUESS_CHECKING $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USER_GUESS
  fi
}

GUESS_CHECKING() {
  USER_NAME=$1 
  CORRECT_ANSWER=$2 
  GUESS_COUNT=$3
  USER_GUESS=$4
  
  if [[ $USER_GUESS -lt $CORRECT_ANSWER ]]
  then
    echo "It's lower than that, guess again:"
    read USER_GUESS
  elif [[ $USER_GUESS -gt $CORRECT_ANSWER ]]
  then
    echo "It's higher than that, guess again:"
    read USER_GUESS
  else
    GUESS_COUNT=$GUESS_COUNT
  fi

  GUESS_COUNT=$(( $GUESS_COUNT + 1 ))
  if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]
  then
    GUESSED_INPUT $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USER_GUESS
  elif [[ $USER_GUESS -lt $CORRECT_ANSWER ]] || [[ $USER_GUESS -gt $CORRECT_ANSWER ]]
  then
    GUESS_CHECKING $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USER_GUESS
  elif [[ $USER_GUESS -eq $CORRECT_ANSWER ]]
  then
    USER_SAVE $USER_NAME $GUESS_COUNT
    NUMBER_OF_GUESSES=$GUESS_COUNT
    SECRET_NUMBER=$CORRECT_ANSWER
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
  fi

}

USER_SAVE() {
  USER_NAME=$1 
  GUESS_COUNT=$2

  CHECK_NAME=$($PSQL "SELECT username FROM users WHERE username='$USER_NAME';")
  if [[ -z $CHECK_NAME ]]
  then
    INSERT_NEW_USER=$($PSQL "INSERT INTO users(username, frequent_games) VALUES('$USER_NAME',1);")
  else
    GET_GAME_PLAYED=$(( $($PSQL "SELECT frequent_games FROM users WHERE username='$USER_NAME';") + 1))
    UPDATE_EXIST_USER=$($PSQL "UPDATE users SET frequent_games=$GET_GAME_PLAYED WHERE username='$USER_NAME';")
  fi
  GAME_SAVE $USER_NAME $GUESS_COUNT
}

GAME_SAVE() {
  USER_NAME=$1 
  NUMBER_OF_GUESSES=$2

  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USER_NAME';")
  INSERT_GAME=$($PSQL "INSERT INTO games(user_id, best_guess) VALUES($USER_ID, $NUMBER_OF_GUESSES);")
  USER_NAME=$($PSQL "SELECT username FROM users WHERE user_id=$USER_ID;")
}


START_GAME
