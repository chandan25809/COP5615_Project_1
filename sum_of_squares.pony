use "collections"

//Boss actor manages task allocation and distributes work to the workers
actor Boss
  let total_num: I64
  let size: I64
  let boss_env: Env
  
  new create( n:I64,k: I64, env: Env) =>
    total_num=n
    size = k
    boss_env = env
    
  be perform_tasks() =>
    boss_env.out.print("performing tasks")
    // A work unit size of 450 minimizes the total number of task allocations (from 10000000 / 450 ≈ 22222 units), 
    //thereby optimizing performance through lesser communication overhead yet still ensuring that there is sufficient 
    //granularity for effective parallelism and efficient distribution of work among the workers.
    var window_size: I64 = 450
    if total_num < 450 then
      window_size = total_num
    end
    //chunk size - unprocessed_window_size
    let unprocessed_window_size: I64 = total_num % window_size
    var window_chunk: I64 = total_num / window_size
    var sliding_window: Array[(I64, I64)] = []

    boss_env.out.print("window Size: " + window_size.string())
    boss_env.out.print("results")

    var starting_segment: I64 = 1

    // Check if both total_num and window_size are even
    if ((total_num % 2) == 0) and ((window_size % 2) == 0) then
        for worker_range in Range[I64](1, window_size) do
            let ending_segment: I64 = (worker_range + 1) * window_chunk
            sliding_window.push((starting_segment, ending_segment))
            starting_segment = ending_segment + 1
        end
    else
        // Handle uneven distribution if either total_num or window_size is odd
        for worker_range in Range[I64](1, window_size - 1) do
            let ending_segment: I64 = (worker_range + 1) * window_chunk
            sliding_window.push((starting_segment, ending_segment))
            starting_segment = ending_segment + 1
        end
        // Handle remaining tasks
        sliding_window.push((starting_segment, total_num))
    end

    for work_range in sliding_window.values() do
      let worker = Worker(this,boss_env)
      worker.process_range(work_range._1, work_range._2, size)
    end


//Worker actor Processes the assigned tasks and checks whether the sum of squares within the given range is a perfect square.
actor Worker
  let _boss: Boss
  let worker_env: Env

  new create( boss:Boss,env: Env) =>
    _boss=boss
    worker_env = env

  be process_range(segment_start: I64, segment_end: I64, size: I64) =>
    for i in Range[I64](segment_start, segment_end+1) do
      if validate_perfect_square_sum(i, size) then
        worker_env.out.print(i.string())
      end
    end

  fun validate_perfect_square_sum(segment_start: I64, size: I64): Bool =>
    var sqrt_sum: I64 = 0
    for value in Range[I64](segment_start, segment_start + size) do
      sqrt_sum = sqrt_sum + (value * value)
    end

    let square_root = calculate_sqrt(sqrt_sum)
    (square_root * square_root) == sqrt_sum

  fun calculate_sqrt(num: I64): I64 =>
    if num == 0 then
      0
    else
      var cur_estimate_val: I64 = num
      var next_estimate_val: I64 = (cur_estimate_val + (num / cur_estimate_val)) / 2
      while next_estimate_val < cur_estimate_val do
        cur_estimate_val = next_estimate_val
        next_estimate_val = (cur_estimate_val + (num / cur_estimate_val)) / 2
      end
      cur_estimate_val
    end


//Entry point
actor Main
  new create(env: Env) =>
    try
      let args = env.args
      let n = args(1)?.i64()?
      let size = args(2)?.i64()?

      let boss = Boss(n, size, env)
      env.out.print(n.string())
      env.out.print(size.string())
      boss.perform_tasks()
    else
      env.out.print("Invalid args")
    end