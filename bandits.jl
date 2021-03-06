type Bandit
  θ::Vector{Float64}
end
Bandit(k::Integer) = Bandit(rand(k))
pull(b::Bandit, i::Integer) = rand() < b.θ[i]
numArms(b::Bandit) = length(b.θ)

function banditTrial(b)
  B = [button("Arm $i") for i = 1:numArms(b)]
  wins = [foldl((acc, value) -> acc + pull(b,i), 0, signal(B[i])) for i = 1:arms]
  tries = [foldl((acc, value) -> acc + 1, 0, signal(B[i])) for i = 1:arms]
  for i = 1:numArms(b)
    display(B[i])
    display(lift((w,t) -> latex(@sprintf("%d wins out of %d tries (%d percent)", w, t, 100*w/t)), wins[i], tries[i]))
  end
  t = togglebuttons(["Hide", "Show"], value="Hide", label="True parameters")
  display(t)
  display(lift(v -> v == "Show" ? latex(string(b.θ)) : latex(""), t))
end

function banditEstimation(b)
  B = [button("Arm $i") for i = 1:numArms(b)]
  wins = [foldl((acc, value) -> acc + pull(b,i), 0, signal(B[i])) for i = 1:arms]
  tries = [foldl((acc, value) -> acc + 1, 0, signal(B[i])) for i = 1:arms]
  for i = 1:numArms(b)
    display(B[i])
    display(lift((w,t) -> latex(@sprintf("%d wins out of %d tries (%d percent)", w, t, 100*w/t)), wins[i], tries[i]))
  end
  display(lift((w1,t1,w2,t2)->
       Axis([
              Plots.Linear(θ->pdf(Beta(w1+1, t1-w1+1), θ), (0,1), legendentry="Beta($(w1+1), $(t1-w1+1))"),
              Plots.Linear(θ->pdf(Beta(w2+1, t2-w2+1), θ), (0,1), legendentry="Beta($(w2+1), $(t2-w2+1))")
              ],
            xmin=0,xmax=1,ymin=0),
       wins[1], tries[1], wins[2], tries[2]
       ))
  t = togglebuttons(["Hide", "Show"], value="Hide", label="True parameters")
  display(t)
  display(lift(v -> v == "Show" ? latex(string(b.θ)) : latex(""), t))
end

type BanditStatistics
    numWins::Vector{Int}
    numTries::Vector{Int}
    BanditStatistics(k::Int) = new(zeros(k), zeros(k))
end
numArms(b::BanditStatistics) = length(b.numWins)
function update!(b::BanditStatistics, i::Int, success::Bool)
    b.numTries[i] += 1
    if success
        b.numWins[i] += 1
    end
end
# win probability assuming uniform prior
winProbabilities(b::BanditStatistics) = (b.numWins + 1)./(b.numTries + 2)

abstract BanditPolicy

function simulate(b::Bandit, policy::BanditPolicy; steps = 10)
    wins = zeros(steps)
    s = BanditStatistics(numArms(b))
    for step = 1:steps
        i = arm(policy, s)
        win = pull(b, i)
        update!(s, i, win)
        wins[step] = wins[max(1, step-1)] + (win ? 1 : 0)
    end
    wins
end

function simulateAverage(b::Bandit, policy::BanditPolicy; steps = 10, iterations = 10)
  ret = zeros(steps)
  for i = 1:iterations
    ret += simulate(b, policy, steps=steps, steps=steps)
  end
  ret ./ iterations
end
