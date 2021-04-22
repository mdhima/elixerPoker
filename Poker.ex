#Poker Assignment #2 - Elixir
#Group: Besar Kapllani - 500943601
#       Maria Dhima - 500972248
defmodule Poker do
    def deal(cards) do
        #make the player hands
        [a,b,c,d|t] = cards
        player1 = [a] ++ [c] ++ t
        player2 = [b] ++ [d] ++ t
        #convert the hands to tuples of the form {value, suit}
        player1 = convertHand(player1)
        player2 = convertHand(player2)
        #sort the hands in ascending numeric order
        player1 = Enum.sort(player1)
        player2 = Enum.sort(player2)
        #begin checking poker rankings, starting with flushes
        p1ranking = checkFlush(player1)
        p2ranking = checkFlush(player2)
        #now check for straights (using unique values), if no flushes
        p1ranking = if !p1ranking, do: checkStraight(Enum.uniq_by(player1, fn {x, _} -> x end), 0), else: p1ranking
        p2ranking = if !p2ranking, do: checkStraight(Enum.uniq_by(player2, fn {x, _} -> x end), 0), else: p2ranking
        #now we must check for duplicate values to see if we can make pairs
        p1ranking = if !p1ranking, do: countCards(player1), else: p1ranking
        p2ranking = if !p2ranking, do: countCards(player2), else: p2ranking
        #now, we compare the player values to each other and tie break to see who wins
        winner = declareWinner(p1ranking, p2ranking)
        printWinner(winner)
    end

    #uses checkSuits helper method to find if it is possible to make a royal/straight/regular flush, if not return flush, if no suits return false
    def checkFlush(cards) do
        flush = checkSuits(cards, "C") || checkSuits(cards, "D") || checkSuits(cards, "H") || checkSuits(cards, "S")
        if flush != false do
            temp = checkStraight(flush, 1)
            if temp, do: [hd(temp)] ++ Enum.take(temp, -5), else: [5] ++ Enum.take(flush, -5) #a regular flush
        else 
            false #not any type of flush
        end
    end

    #checkStraight assumes all cards passed are unique, and compares adjacent cards in the list with tail recursion
    def checkStraight(cards, ranking) do #initial call
        ace = if elem(hd(cards), 0) == 1, do: hd(cards), else: false #check for an ace used in royal/straight flush
        checkStraight(tl(cards), hd(cards), ace, [], ranking)
    end
    def checkStraight([], head, ace, buildlist, ranking) do #final call
        buildlist = if length(buildlist) >= 4 do
            if ace && elem(head, 0) == 13 && elem(hd(Enum.reverse(buildlist)), 0) == 13, do: buildlist ++ [ace], else: buildlist #check if we can add an ace to the end
        else
            buildlist
        end
        if length(buildlist) < 5 do 
            false 
        else
            if ranking == 1 do #if 1, it was called from getflush, so it could be either royal or straight flush
                if elem(hd(Enum.take(buildlist, -1)), 0) == 1, do: [ranking] ++ buildlist, else: [2] ++ buildlist #either royal or straight flush
            else
                [6] ++ buildlist #if its 5 long, but not called in checkFlush, its a regular straight
            end
        end
    end
    def checkStraight(list, head, ace, buildlist, ranking) do #tail-recursive call
        buildlist = 
        if (elem(head, 0)+1) == elem(hd(list), 0) do #if the elements in sequence
            if buildlist == [], do: [head] ++ [hd(list)], else: #if list empty, add both values
                if elem(hd(Enum.reverse(buildlist)), 0)+1 == elem(hd(list), 0), do: buildlist ++ [hd(list)], else: buildlist
        else
            if length(buildlist) < 5 do
                if length(buildlist) == 4 do
                    if elem(hd(Enum.reverse(buildlist)), 0) == 13, do: buildlist, else: []
                else
                    []
                end
            else
                buildlist
            end
        end
        checkStraight(tl(list), hd(list), ace, buildlist, ranking)
    end

    #using a frequency map with key value pairs, we know which cards appear most often in the given hand
    def countCards(cards) do
        return = false
        frequencies = checkFreq(cards)
        type1 = hd(frequencies)
        type2 = hd(tl(frequencies))
        acecheck = hd(Enum.take(frequencies, -1))
        type3 = if elem(acecheck, 0) == 1 do #if we have a solo ace, use the ace
            acecheck
        else
            hd(tl(tl(frequencies))) #else use the third pair found in checkfreq
        end
        return = if elem(type1, 1) == 4 do #if four of a kind
            if elem(type2, 1) != 1 do #if we cant combine 4 cards with one card
                [3] ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type3, 0)) #use the ace/highest single
            else 
                [3] ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type2, 0)) #otherwise use the second pair
            end
        else
            return
        end
        return = if !return do
            if elem(type1, 1) == 3 && elem(type2, 1) == 2 do #if full house
                if elem(type3, 1) == 2 && elem(type3, 0) == 1 do #if the third pair is a pair of aces
                    [4] ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type3, 0)) #use those aces
                else
                    [4] ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type2, 0)) #otherwise use the second pair
                end
            end
        else return
        end
        return = if !return do
            if elem(type1, 1) == 3 do #if 3 of a kind, previous call ensures no 3,2
                if elem(type2, 1) == 3 do #its possible to have 2 3 of a kinds, use the largest in case this one is 3 aces
                    if elem(type2, 0) == 1 do #if they are actually aces
                       temp = [7] ++ getCardGroup(cards, elem(type2, 0)) ++ getCardGroup(cards, elem(type1, 0)) #NOTE: its possible for the 3 of a kind not to be larger than the solo card
                       Enum.take(temp, 6)
                    else
                        temp = [7] ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type2, 0))
                        Enum.take(temp, 6)
                    end
                else
                    if elem(type3, 0) == 1 do
                        [7] ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type3, 0)) ++ getCardGroup(cards, elem(type2, 0))
                    else
                        [7] ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type2, 0)) ++ getCardGroup(cards, elem(type3, 0))
                    end
                end
            end
        else 
            return
        end
        return = if !return do
            if elem(type1, 1) == 2 do #if pair
                if elem(type2, 1) == 2 do #if 2 pair
                    if elem(type3, 1) == 2 do #if there are 3 pairs NOTE: the third pair might be smaller than the solo card
                        if elem(type3, 0) == 1 do #if one pair is a pair of aces
                            [8] ++ getCardGroup(cards, elem(type3, 0)) ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type2, 0))
                        else
                            [8] ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type2, 0)) ++ getCardGroup(cards, elem(type3, 0))
                        end
                    else #only 2 pairs
                        if elem(type2, 0) == 1 do #if one pair is aces
                            [8] ++ getCardGroup(cards, elem(type2, 0)) ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type3, 0))
                        else
                            [8] ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type2, 0)) ++ getCardGroup(cards, elem(type3, 0))
                        end
                    end
                else #if only pair
                    if elem(type3, 0) == 1 do #if we have a solo ace
                        [9] ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type3, 0)) ++ getCardGroup(cards, elem(type2, 0)) ++ getCardGroup(cards, elem(hd(tl(tl(frequencies))), 0))
                    else
                        [9] ++ getCardGroup(cards, elem(type1, 0)) ++ getCardGroup(cards, elem(type2, 0)) ++ getCardGroup(cards, elem(type3, 0)) ++ getCardGroup(cards, elem(hd(tl(tl(tl(frequencies)))), 0))
                    end
                end
            end
        else
            return
        end
        if !return do #if it is simply high card
            if elem(type3, 0) == 1 do #if there is a high ace
                temp = [10] ++ Enum.take(cards, 1) ++ Enum.reverse(cards)
                Enum.take(temp, 6)
            else
                [10] ++ Enum.take(Enum.reverse(cards), 5)
            end
        else
            return
        end
    end

    #straightforward enough
    def declareWinner(player1, player2) do
        player1 = if hd(player1) == 1 || hd(player1) == 2 || hd(player1) == 5 || hd(player1) == 6, do: [hd(player1)] ++ Enum.reverse(tl(player1)), else: player1
        player2 = if hd(player2) == 1 || hd(player2) == 2 || hd(player2) == 5 || hd(player2) == 6, do: [hd(player2)] ++ Enum.reverse(tl(player2)), else: player2
        if hd(player1) == hd(player2) do
            if breakTie(tl(player1), tl(player2)) == 1, do: player1, else: player2 #if breaktie returns 1, player 1 wins, else player 2 wins
        else
            if hd(player1) < hd(player2), do: player1, else: player2
        end
    end

    #compare each value with each other
    def breakTie([p1h | p1t], [p2h | p2t]) do
        if elem(p1h, 0) == elem(p2h, 0) do #if they are the same, recursive call with tail of list
            breakTie(p1t, p2t)
        else
            num1 = elem(p1h, 0)
            num2 = elem(p2h, 0)
            num1 = if num1 == 1, do: 14, else: num1
            num2 = if num2 == 1, do: 14, else: num2
            if num1 > num2 do
                1
            else
                2
            end
        end
    end
    def breakTie([], []) do #if both hands are completely identical, just give it to player 1
        1
    end
    def breakTie(_, []) do
        1
    end
    def breakTie([], _) do
        2
    end

    #prints out the winner, properly formatted
    def printWinner(winner) do
        winner = Enum.take(winner, 6)
        if hd(winner) == 1 || hd(winner) == 2 || hd(winner) == 4 || hd(winner) == 5 || hd(winner) == 6 || hd(winner) == 10 do #print all 5 cards
            combineList(Enum.reverse(tl(winner)))
        else
            if hd(winner) == 3 || hd(winner) == 8 do #print 4 cards
                combineList(tl(Enum.reverse(tl(winner))))
            else
                if hd(winner) == 7 do #print 3 cards
                    combineList(tl(tl(Enum.reverse(tl(winner)))))
                else #print 2 cards
                    combineList(tl(tl(tl(Enum.reverse(tl(winner))))))
                end
            end
        end 
    end

    #converts the list of integers to a list of tuples of the form {value, suit}
    def convertHand(cards) do
        value = fn(n) -> if rem(n, 13) == 0, do: 13, else: rem(n, 13) end
        suit = fn(n) -> x = div(n-1, 13)
            cond do
                x == 0 -> "C"
                x == 1 -> "D"
                x == 2 -> "H"
                x == 3 -> "S"
            end
        end
        Enum.map(cards, fn(n) -> {value.(n), suit.(n)} end)
    end

    #returns a list of the cards which share the same given suit, false if none > 4 (cannot create flush)
    def checkSuits(cards, s) do
        temp = Enum.filter(cards, fn(n) ->
            {_, suit} = n
            suit == s
        end)
        if (length temp) > 4, do: temp, else: false
    end

    #uses Enum.frequencies to see how often things show up, using the top 2 frequency pairs for the ranking
    def checkFreq(cards) do
        Enum.frequencies_by(cards, fn {x, _} -> x end) |> Enum.sort_by(&(elem(&1, 1))) |> Enum.reverse()
    end

    # gets the cards we want
    def getCardGroup(cards, num) do
        Enum.filter(cards, fn tuple -> 
            {card, _} = tuple
            card == num
        end)
    end

    #formats the winning hand to be printed
    def combineList(cards) do
        Enum.map(cards, fn({num, suit}) -> Integer.to_string(num) <> suit end)
    end

    #checks if there are flush streaks of this length
    def checkIfMoreThan(cards, num) do 
        Enum.find(cards, fn(tuple) -> 
            {_, val} = tuple
            val >= num 
        end)
    end
end