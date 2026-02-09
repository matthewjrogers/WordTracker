```markdown
# WordTracker.vim

A minimal word count tracking plugin for writers. Set a daily word count goal, track your progress across sessions, and view your writing streak on a calendar.

## Features

- **Daily word count tracking** - Counts net words written across all files while tracking is active
- **Persistent goals** - Set your target once, it applies every day until you change it
- **Multiple stars** - Earn multiple stars per day by hitting multiples of your target
- **Calendar view** - See your current month with stars for each day you hit your goal
- **Streak tracking** - Track consecutive days of hitting your target
- **Session-based activation** - Only counts words when you explicitly start tracking

## Installation

### Manual

```bash
mkdir -p ~/.vim/plugin
curl -o ~/.vim/plugin/wordtracker.vim [URL_TO_RAW_FILE]
```

### vim-plug

```vim
Plug 'yourusername/wordtracker.vim'
```

### Vundle

```vim
Plugin 'yourusername/wordtracker.vim'
```

### packer.nvim

```lua
use 'yourusername/wordtracker.vim'
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:WordTracker` | Start tracking words for this session |
| `:WordTrackerStop` | Stop tracking words |
| `:WordTarget N` | Set daily goal to N words (persists until changed) |
| `:WordStatus` | Show today's progress, stars earned, and words until next star |
| `:WordCalendar` | Open calendar view showing current month and streak |

### Quick Start

1. Set your daily target (only need to do this once):
   ```
   :WordTarget 500
   ```

2. Start tracking when you begin writing:
   ```
   :WordTracker
   ```

3. Write and save your work as normal. You'll see a notification each time you earn a star.

4. Check your progress anytime:
   ```
   :WordStatus
   ```

5. View your calendar and streak:
   ```
   :WordCalendar
   ```

### Example Status Output

```
WordTracker Status:
  Today: 750 words
  Target: 500 words
  Stars: 1 ★
  Next star in: 250 words
  Session: 750 words (tracking active)
```

### Example Calendar Output

```
WordTracker Calendar
====================

  January 2025

 Su  Mo  Tu  We  Th  Fr  Sa
----------------------------
          ★   ★   ★★  ★   4
 5   6   ★   ★   9  10  11
12  13  14  15  16  17  18
19  20  21  22  23  24  25
26  27  28  29  30  31

----------------------------
Current streak: 4 days
Target: 500 words

(Press q to close)
```

## How It Works

### Word Counting

- Uses Vim's built-in `wordcount()` function
- Tracks the *net* change in words (deletions reduce your count)
- Counts words across all buffers while tracking is active
- Only counts words in files you save

### Data Storage

WordTracker stores data in `~/.vim/wordtracker.json`:

```json
{
  "target": 500,
  "days": [
    {"date": "2025-01-06", "words": 523},
    {"date": "2025-01-07", "words": 1050}
  ]
}
```

### Multiple Sessions Per Day

If you write in multiple sessions throughout the day, your word counts accumulate. Morning session of 300 words plus evening session of 200 words equals 500 words for the day.

### Stars

Stars are calculated as `floor(words / target)`. With a 500-word target:
- 499 words = 0 stars
- 500 words = 1 star
- 999 words = 1 star
- 1000 words = 2 stars

You receive a notification each time you cross a new star threshold.

### Streak

Your streak counts consecutive days where you earned at least one star. Missing a day resets the streak to zero. Today doesn't break your streak if you haven't hit your target yet—only completed days count against you.

## Integration with Other Plugins

WordTracker pairs well with distraction-free writing setups. Example integration with [goyo.vim](https://github.com/junegunn/goyo.vim) and [vim-pencil](https://github.com/preservim/vim-pencil):

```vim
function! s:WritingModeStart()
  WordTracker
  Goyo
  SoftPencil
endfunction

function! s:WritingModeStop()
  WordTrackerStop
  Goyo!
  NoPencil
endfunction

command! WriteOn call s:WritingModeStart()
command! WriteOff call s:WritingModeStop()
```

## Configuration

Currently, WordTracker uses sensible defaults with no configuration options. The data file is stored at `~/.vim/wordtracker.json`.

## Requirements

- Vim 8.0+ (for `json_encode`/`json_decode`)
- Unix-like system (Linux, macOS) for date calculations

## License

MIT

## Contributing

Issues and pull requests welcome.
```
