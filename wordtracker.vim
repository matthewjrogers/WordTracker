" wordtracker.vim - Daily word count tracking for writers
" Place in ~/.vim/plugin/wordtracker.vim

if exists('g:loaded_wordtracker')
  finish
endif
let g:loaded_wordtracker = 1

" --- Configuration ---
let s:data_file = expand('~/.vim/wordtracker.json')
let s:tracking = 0
let s:buffer_baselines = {}
let s:session_words = 0
let s:stars_notified = 0

" --- Data Persistence ---
function! s:LoadData()
  if filereadable(s:data_file)
    try
      let l:content = join(readfile(s:data_file), '')
      return json_decode(l:content)
    catch
      return {'target': 500, 'days': []}
    endtry
  endif
  return {'target': 500, 'days': []}
endfunction

function! s:SaveData(data)
  let l:dir = fnamemodify(s:data_file, ':h')
  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p')
  endif
  call writefile([json_encode(a:data)], s:data_file)
endfunction

" --- Word Counting ---
function! s:GetBufferWords()
  return wordcount().words
endfunction

function! s:GetToday()
  return strftime('%Y-%m-%d')
endfunction

function! s:GetTodayWords(data)
  let l:today = s:GetToday()
  for l:day in a:data.days
    if l:day.date == l:today
      return l:day.words
    endif
  endfor
  return 0
endfunction

function! s:UpdateTodayWords(data, words)
  let l:today = s:GetToday()
  for l:day in a:data.days
    if l:day.date == l:today
      let l:day.words = a:words
      return
    endif
  endfor
  call add(a:data.days, {'date': l:today, 'words': a:words})
endfunction

" --- Tracking ---
function! s:StartTracking()
  if s:tracking
    echo "WordTracker: Already tracking"
    return
  endif
  
  let s:tracking = 1
  let s:buffer_baselines = {}
  let s:session_words = 0
  
  " Set baseline for current buffer
  let s:buffer_baselines[bufnr('%')] = s:GetBufferWords()
  
  " Check how many stars already earned today for notification tracking
  let l:data = s:LoadData()
  let l:today_words = s:GetTodayWords(l:data)
  let s:stars_notified = l:data.target > 0 ? l:today_words / l:data.target : 0
  
  augroup WordTracker
    autocmd!
    autocmd BufEnter * call s:OnBufEnter()
    autocmd BufWritePost * call s:OnSave()
  augroup END
  
  echo "WordTracker: Started tracking"
endfunction

function! s:StopTracking()
  if !s:tracking
    echo "WordTracker: Not currently tracking"
    return
  endif
  
  let s:tracking = 0
  augroup WordTracker
    autocmd!
  augroup END
  
  echo "WordTracker: Stopped tracking"
endfunction

function! s:OnBufEnter()
  let l:bufnr = bufnr('%')
  if !has_key(s:buffer_baselines, l:bufnr)
    let s:buffer_baselines[l:bufnr] = s:GetBufferWords()
  endif
endfunction

function! s:OnSave()
  let l:bufnr = bufnr('%')
  
  " Set baseline if we don't have one
  if !has_key(s:buffer_baselines, l:bufnr)
    let s:buffer_baselines[l:bufnr] = s:GetBufferWords()
    return
  endif
  
  " Calculate delta for this buffer
  let l:current = s:GetBufferWords()
  let l:baseline = s:buffer_baselines[l:bufnr]
  let l:delta = l:current - l:baseline
  
  " Update baseline
  let s:buffer_baselines[l:bufnr] = l:current
  
  " Update session total
  let s:session_words += l:delta
  
  " Persist to file
  let l:data = s:LoadData()
  let l:today_words = s:GetTodayWords(l:data) + l:delta
  call s:UpdateTodayWords(l:data, l:today_words)
  call s:SaveData(l:data)
  
  " Check for star notifications
  if l:data.target > 0
    let l:stars_earned = l:today_words / l:data.target
    if l:stars_earned > s:stars_notified
      let s:stars_notified = l:stars_earned
      echohl WarningMsg
      echo "★ WordTracker: Target hit! (" . l:stars_earned . " star" . (l:stars_earned > 1 ? "s" : "") . " today)"
      echohl None
    endif
  endif
endfunction

" --- Commands ---
function! s:SetTarget(target)
  let l:target = str2nr(a:target)
  if l:target <= 0
    echo "WordTracker: Target must be a positive number"
    return
  endif
  
  let l:data = s:LoadData()
  let l:data.target = l:target
  call s:SaveData(l:data)
  echo "WordTracker: Target set to " . l:target . " words"
endfunction

function! s:ShowStatus()
  let l:data = s:LoadData()
  let l:today_words = s:GetTodayWords(l:data)
  let l:target = l:data.target
  let l:stars = l:target > 0 ? l:today_words / l:target : 0
  let l:next_star = l:target - (l:today_words % l:target)
  
  echo "WordTracker Status:"
  echo "  Today: " . l:today_words . " words"
  echo "  Target: " . l:target . " words"
  echo "  Stars: " . l:stars . " ★"
  if l:target > 0
    echo "  Next star in: " . l:next_star . " words"
  endif
  if s:tracking
    echo "  Session: " . s:session_words . " words (tracking active)"
  else
    echo "  Tracking: inactive"
  endif
endfunction

" --- Calendar ---
function! s:CalculateStreak(data)
  let l:streak = 0
  let l:check_date = localtime()
  let l:target = a:data.target
  
  if l:target <= 0
    return 0
  endif
  
  " Build a dict of dates to words for quick lookup
  let l:date_words = {}
  for l:day in a:data.days
    let l:date_words[l:day.date] = l:day.words
  endfor
  
  " Count backwards from today
  while 1
    let l:date_str = strftime('%Y-%m-%d', l:check_date)
    let l:words = get(l:date_words, l:date_str, 0)
    
    if l:words >= l:target
      let l:streak += 1
      let l:check_date -= 86400  " Go back one day
    else
      " If it's today and we haven't hit target yet, don't break streak
      " Just check yesterday onwards
      if l:date_str == s:GetToday()
        let l:check_date -= 86400
        continue
      endif
      break
    endif
  endwhile
  
  return l:streak
endfunction

function! s:ShowCalendar()
  let l:data = s:LoadData()
  let l:target = l:data.target
  
  " Build date lookup
  let l:date_words = {}
  for l:day in l:data.days
    let l:date_words[l:day.date] = l:day.words
  endfor
  
  " Get current month info
  let l:year = str2nr(strftime('%Y'))
  let l:month = str2nr(strftime('%m'))
  let l:month_name = strftime('%B %Y')
  
  " First day of month (0=Sunday, 6=Saturday)
  let l:first_day_ts = s:DateToTimestamp(l:year, l:month, 1)
  let l:first_weekday = str2nr(strftime('%w', l:first_day_ts))
  
  " Days in month
  let l:days_in_month = s:DaysInMonth(l:year, l:month)
  
  " Build calendar lines
  let l:lines = []
  call add(l:lines, "WordTracker Calendar")
  call add(l:lines, "====================")
  call add(l:lines, "")
  call add(l:lines, "  " . l:month_name)
  call add(l:lines, "")
  call add(l:lines, " Su  Mo  Tu  We  Th  Fr  Sa")
  call add(l:lines, "----------------------------")
  
  " Build weeks
  let l:line = ""
  let l:day = 1
  
  " Padding for first week
  for i in range(l:first_weekday)
    let l:line .= "    "
  endfor
  
  " Fill in days
  let l:weekday = l:first_weekday
  while l:day <= l:days_in_month
    let l:date_str = printf('%04d-%02d-%02d', l:year, l:month, l:day)
    let l:words = get(l:date_words, l:date_str, 0)
    let l:stars = l:target > 0 ? l:words / l:target : 0
    
    if l:stars > 0
      let l:display = repeat('★', min([l:stars, 2]))
      let l:display = printf('%2s', l:display)
    else
      let l:display = printf('%2d', l:day)
    endif
    
    let l:line .= " " . l:display . " "
    let l:weekday += 1
    
    if l:weekday == 7
      call add(l:lines, l:line)
      let l:line = ""
      let l:weekday = 0
    endif
    
    let l:day += 1
  endwhile
  
  " Add final partial week
  if l:line != ""
    call add(l:lines, l:line)
  endif
  
  " Add streak info
  let l:streak = s:CalculateStreak(l:data)
  call add(l:lines, "")
  call add(l:lines, "----------------------------")
  call add(l:lines, "Current streak: " . l:streak . " day" . (l:streak != 1 ? "s" : ""))
  call add(l:lines, "Target: " . l:target . " words")
  call add(l:lines, "")
  call add(l:lines, "(Press q to close)")
  
  " Display in split
  below new
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nobuflisted
  setlocal nonumber
  setlocal norelativenumber
  file WordTracker\ Calendar
  
  call setline(1, l:lines)
  setlocal nomodifiable
  
  nnoremap <buffer> q :close<CR>
endfunction

function! s:DateToTimestamp(year, month, day)
  return system('date -d "' . a:year . '-' . printf('%02d', a:month) . '-' . printf('%02d', a:day) . '" +%s')
endfunction

function! s:DaysInMonth(year, month)
  let l:days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  let l:d = l:days[a:month - 1]
  
  " Leap year check for February
  if a:month == 2
    if (a:year % 4 == 0 && a:year % 100 != 0) || (a:year % 400 == 0)
      let l:d = 29
    endif
  endif
  
  return l:d
endfunction

" --- Command Definitions ---
command! WordTracker call s:StartTracking()
command! WordTrackerStop call s:StopTracking()
command! -nargs=1 WordTarget call s:SetTarget(<q-args>)
command! WordStatus call s:ShowStatus()
command! WordCalendar call s:ShowCalendar()
