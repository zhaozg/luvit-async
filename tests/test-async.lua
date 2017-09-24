local async = require '../async'
local timer = require 'timer'
local deep_equal = require('./libs/deep-equal')

local function equals(a, b)
  assert(a == b)
end

require('./libs/tap')(function(test)

  test("test_forEach", function()
    local args = {}
    async.forEach({ 1, 3, 2 }, function(x, callback)
      timer.setTimeout(x * 25, function()
        table.insert(args, x)
        callback()
      end)
    end, function(err)
      deep_equal(args, { 1, 2, 3 })
    end)
  end)


  test("test_forEachTable", function()
    local test_table = {
      horse = "hay",
      cat = "chow",
      cow = "cud"
    }
    local test_table_len = 3
    local count = 0

    async.forEachTable(test_table, function(key, value, callback)
      assert(test_table[key] == value)
      count = count + 1
      callback()
    end, function(err)
      assert(count == test_table_len)

    end)
  end)

  test("test_forEachEmptyArray", function()
    local args = {}
    async.forEach({}, function(x, callback)
      assert(false, 'iterator should not be called')
      callback()
    end, function(err)
      assert(true, "should be called")

    end)
  end)

  test("test_forEachError", function()
    local args = {}
    async.forEach({ 1, 2, 3 }, function(x, callback)
      table.insert(args, x)
      callback({ "error" })
    end, function(err)
      assert(err ~= nil)
      assert(#args == 1)
      assert(args[1] == 1)

    end)
  end)

  test("forEachSeries", function()
    local args = {}
    async.forEachSeries({ 1, 3, 2 }, function(x, callback)
      timer.setTimeout(x * 23, function()
        table.insert(args, x)
        callback()
      end)
    end, function(err)
      deep_equal(args, { 1, 3, 2 })

    end)
  end)

  test("forEachSeries with Empty Array", function()
    local args = {}
    async.forEachSeries({}, function(x, callback)
      assert(false, 'iterator should not be called')
      callback()
    end, function(err)
      assert(true, "should be called")

    end)
  end)

  test("forEachSeries with Error", function()
    local args = {}
    async.forEachSeries({ 1, 2, 3 }, function(x, callback)
      table.insert(args, x)
      callback({ "error" })
    end, function(err)
      assert(err ~= nil)
      assert(#args == 1)
      assert(args[1] == 1)

    end)
  end)

  test("forEachLimit", function()
    local args = {}
    local arr = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
    async.forEachLimit(arr, 2, function(x, callback)
      timer.setTimeout(x * 5, function()
        table.insert(args, x)
        callback()
      end)
    end, function(err)
      deep_equal(arr, args)

    end)
  end)

  test("forEachLimit with Empty Array", function()
    async.forEachLimit({}, 2, function(x, callback)
      assert(false, 'iterator should not be called')
    end, function(err)
      assert(true, 'should be called')

    end)
  end)

  test("test_forEachLimitExceedsSize", function()
    local args = {}
    local arr = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
    async.forEachLimit(arr, 20, function(x, callback)
      timer.setTimeout(x * 25, function()
        table.insert(args, x)
        callback()
      end)
    end, function(err)
      deep_equal(args, arr)

    end)
  end)

  test("test_forEachLimitEqualSize", function()
    local args = {}
    local arr = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
    async.forEachLimit(arr, 10, function(x, callback)
      timer.setTimeout(x * 5, function()
        table.insert(args, x)
        callback()
      end)
    end, function(err)
      deep_equal(args, arr)

    end)
  end)

  test("test_forEachLimitZeroSize", function()
    local args = {}
    local arr = { 0, 1, 2, 3, 4, 5 }
    async.forEachLimit(arr, 0, function(x, callback)
      assert(false, 'iterator should not be called')
      callback()
    end, function(err)
      assert(true, 'callback should be called')

    end)
  end)

  test("test_forEachLimitError", function()
    local args = {}
    local arr = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
    async.forEachLimit(arr, 3, function(x, callback)
      table.insert(args, x)
      if x == 2 then
        callback({ "error" })
      end
    end, function(err)
      assert(err)
      deep_equal(args, { 0, 1, 2 })

    end)
  end)

  test("test_series", function()
    local call_order = {}
    async.series({
      function(callback)
        timer.setTimeout(25, function()
          table.insert(call_order, 1)
          callback(nil, 1)
        end)
      end,
      function(callback)
        timer.setTimeout(50, function()
          table.insert(call_order, 2)
          callback(nil, 2)
        end)
      end,
      function(callback)
        timer.setTimeout(15, function()
          table.insert(call_order, 3)
          callback(nil, { 3, 3 })
        end)
      end
    }, function(err, results)
      equals(err, nil)
      equals(results[1], 1)
      equals(results[2], 2)
      deep_equal(results[3], { 3, 3 })
      deep_equal(call_order, { 1, 2, 3 })

    end)
  end)

  test("test_seriesEmptyArray", function()
    async.series({}, function(err, results)
      equals(err, nil)
      deep_equal(results, {})

    end)
  end)

  test("test_seriesError", function()
    async.series({
      function(callback)
        callback('error')
      end,
      function(callback)
        assert(false, 'should not be called')
        callback()
      end
    }, function(err, results)
      equals(err, 'error')
      deep_equal(results, {})

    end)
  end)

  test("test_seriesNoCallback", function()
    async.series({
      function(callback) callback() end,
      function(callback) callback(); end
    })
  end)

  test("test_seriesObject", function()
    local call_order = {}
    local ops = {
      one = function(callback)
        timer.setTimeout(25, function()
          table.insert(call_order, 1)
          callback(nil, 1)
        end)
      end,
      two = function(callback)
        timer.setTimeout(50, function()
          table.insert(call_order, 2)
          callback(nil, 2)
        end)
      end,
      three = function(callback)
        timer.setTimeout(15, function()
          table.insert(call_order, 3)
          callback(nil, 3)
        end)
      end
    }
    async.series(ops, function(err, results)
      deep_equal(call_order, { 2, 1, 3 })
      deep_equal(results, { three = 3, one = 1, two = 2 })

    end)
  end)

  test("test_iterator", function()
    local call_order = {}
    local iterator = async.iterator({
      function()
        table.insert(call_order, 1)
      end,
      function(arg1)
        equals(arg1, 'arg1')
        table.insert(call_order, 2)
      end,
      function(arg1, arg2)
        equals(arg1, 'arg1')
        equals(arg2, 'arg2')
        table.insert(call_order, 3)
      end
    })
    iterator.run()
    deep_equal(call_order, { 1 })
    local iterator2 = iterator.run()
    deep_equal(call_order, { 1, 1 })
    local iterator3 = iterator2.run('arg1')
    deep_equal(call_order, { 1, 1, 2 })
    local iterator4 = iterator3.run('arg1', 'arg2')
    deep_equal(call_order, { 1, 1, 2, 3 })
    equals(iterator4, nil)

  end)

  test("test_waterfall", function()
    local call_order = {}
    async.waterfall({
      function(callback)
        table.insert(call_order, 'fn1')
        timer.setTimeout(0, function()
          callback(nil, 'one', 'two')
        end)
      end,
      function(arg1, arg2, callback)
        table.insert(call_order, 'fn2')
        equals(arg1, 'one')
        equals(arg2, 'two')
        timer.setTimeout(25, function()
          callback(nil, arg1, arg2, 'three')
        end)
      end,
      function(arg1, arg2, arg3, callback)
        table.insert(call_order, 'fn3')
        equals(arg1, 'one')
        equals(arg2, 'two')
        equals(arg3, 'three')
        callback(nil, 'four')
      end,
      function(arg4, callback)
        table.insert(call_order, 'fn4')
        deep_equal(call_order, { 'fn1', 'fn2', 'fn3', 'fn4' })
        callback(nil, 'test')
      end
    }, function(err)

    end)
  end)

  test("test_waterfallEmptyArray", function()
    async.waterfall({}, function(err)

    end)
  end)

  test("test_waterfallNoCallback", function()
    async.waterfall({
      function(callback)
        callback()
      end,
      function(callback)
        callback()

      end
    })
  end)

  test("test_waterfallAsync", function()
    local call_order = {}
    async.waterfall({
      function(callback)
        table.insert(call_order, 1)
        callback()
        table.insert(call_order, 2)
      end,
      function(callback)
        table.insert(call_order, 3)
        callback()
      end,
      function()
        deep_equal(call_order, { 1, 2, 3 })

      end
    })
  end)

  test("test_waterfallError", function()
    async.waterfall({
      function(callback)
        callback('error')
      end,
      function(callback)
        assert(false, 'Function should not be called')
        callback()
      end
    }, function(err)
      equals(err, 'error')

    end)
  end)

  test("test_waterfallMultipleCallbacks", function()
    local call_order = {}
    local arr
    arr = {
      function(callback)
        table.insert(call_order, 1)
        -- Call the callback twice, should call function 2 twice
        callback(null, 'one', 'two')
        callback(null, 'one', 'two')
      end,
      function(arg1, arg2, callback)
        table.insert(call_order, 2)
        callback(nil, arg1, arg2, 'three')
      end,
      function(arg1, arg2, arg3, callback)
        table.insert(call_order, 3)
        callback(nil, 'four')
      end,
      function(arg4)
        table.insert(call_order, 4)
        arr[4] = function()
          table.insert(call_order, 4)
          deep_equal(call_order, { 1, 2, 2, 3, 3, 4, 4 });

        end
      end
    }
    async.waterfall(arr)
  end)

  test("test_parallel", function()
    local call_order = {}
    async.parallel({
      function(callback)
        timer.setTimeout(50, function()
          table.insert(call_order, 1)
          callback(nil, 1)
        end)
      end,
      function(callback)
        timer.setTimeout(100, function()
          table.insert(call_order, 2)
          callback(nil, 2)
        end)
      end,
      function(callback)
        timer.setTimeout(25, function()
          table.insert(call_order, 3)
          callback(nil, 3, 3)
        end)
      end
    },
      function(err, results)
        deep_equal(call_order, { 3, 1, 2 })
        deep_equal(results[1], { 1 })
        deep_equal(results[2], { 2 })
        deep_equal(results[3], { 3, 3 })

      end)
  end)

  test("test_parallelEmpty", function()
    async.parallel({}, function(err, results)
      equals(err, nil)
      deep_equal(results, {})

    end)
  end)

  test("test_parallelError", function()
    async.parallel({
      function(callback)
        callback('error', 1)
      end,
      function(callback)
        callback('error2', 2)
      end
    }, function(err, results)
      equals(err, 'error')

    end)
  end)

  test("test_parallelNoCallback", function()
    async.parallel({
      function(callback) callback() end,
      function(callback) callback(); end
    })
  end)

  test("test_parallelObject", function()
    local call_order = {}
    local ops = {}
    ops.one = function(callback)
      timer.setTimeout(25, function()
        table.insert(call_order, 1)
        callback(nil, 1)
      end)
    end
    ops.two = function(callback)
      timer.setTimeout(50, function()
        table.insert(call_order, 2)
        callback(nil, 2)
      end)
    end
    ops.three = function(callback)
      timer.setTimeout(15, function()
        table.insert(call_order, 3)
        callback(nil, 3)
      end)
    end
    async.parallel(ops, function(err, results)
      deep_equal(call_order, { 3, 1, 2 })
      deep_equal(results.three, { 3 })
      deep_equal(results.two, { 2 })
      deep_equal(results.one, { 1 })

    end)
  end)

  test("test_queue", function()
    local call_order = {}
    local delays = { 40, 20, 60, 20 }
    local delay_index = 1
    local q = async.queue(function(task, callback)
      timer.setTimeout(delays[delay_index], function()
        table.insert(call_order, 'process ' .. task);
        callback('error', 'arg');
      end)
      delay_index = delay_index + 1
    end, 2)

    q.push(1, function(err, arg)
      equals(err, 'error')
      equals(arg, 'arg')
      equals(q.length(), 1)
      table.insert(call_order, 'callback ' .. 1)
    end)
    q.push(2, function(err, arg)
      equals(err, 'error')
      equals(arg, 'arg')
      equals(q.length(), 2)
      table.insert(call_order, 'callback ' .. 2)
    end)
    q.push(3, function(err, arg)
      equals(err, 'error')
      equals(arg, 'arg')
      equals(q.length(), 0)
      table.insert(call_order, 'callback ' .. 3)
    end)
    q.push(4, function(err, arg)
      equals(err, 'error')
      equals(arg, 'arg')
      equals(q.length(), 0)
      table.insert(call_order, 'callback ' .. 4)
    end)

    equals(q.length(), 4)
    equals(q.concurrency, 2)

    timer.setTimeout(200, function()
      deep_equal(call_order, {
        "process 2",
        "callback 2",
        "process 1",
        "callback 1",
        "process 4",
        "callback 4",
        "process 3",
        "callback 3"
      })
      equals(q.length(), 0)
      equals(q.concurrency, 2)

    end)
  end)

  test("test_queueChangeConcurrency", function()
    local call_order = {}
    local delays = { 40, 20, 60, 20 }
    local delay_index = 1
    local q = async.queue(function(task, callback)
      timer.setTimeout(delays[delay_index], function()
        table.insert(call_order, 'process ' .. task);
        callback('error', 'arg');
      end)
      delay_index = delay_index + 1
    end, 2)

    q.push(1, function(err, arg)
      equals(err, 'error')
      equals(arg, 'arg')
      equals(q.length(), 3)
      table.insert(call_order, 'callback ' .. 1)
    end)
    q.push(2, function(err, arg)
      equals(err, 'error')
      equals(arg, 'arg')
      equals(q.length(), 2)
      table.insert(call_order, 'callback ' .. 2)
    end)
    q.push(3, function(err, arg)
      equals(err, 'error')
      equals(arg, 'arg')
      equals(q.length(), 1)
      table.insert(call_order, 'callback ' .. 3)
    end)
    q.push(4, function(err, arg)
      equals(err, 'error')
      equals(arg, 'arg')
      equals(q.length(), 0)
      table.insert(call_order, 'callback ' .. 4)
    end)

    equals(q.length(), 4)
    equals(q.concurrency, 2)
    q.concurrency = 1

    timer.setTimeout(250, function()
      deep_equal(call_order, {
        "process 1",
        "callback 1",
        "process 2",
        "callback 2",
        "process 3",
        "callback 3",
        "process 4",
        "callback 4"
      })
      equals(q.concurrency, 1)
      equals(q.length(), 0)

    end)
  end)
end)
