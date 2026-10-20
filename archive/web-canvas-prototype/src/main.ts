import './style.css'
import { interact } from './game/ecosystem'
import { clockLabel, Game, seasonJa, weatherJa } from './game/Game'
import type { Interaction } from './game/types'

const app = document.querySelector<HTMLDivElement>('#app')!
app.innerHTML = `
  <canvas id="forest" aria-label="Forests の森"></canvas>

  <section class="screen-title" id="title">
    <div class="title-panel">
      <h1 class="brand">Forests</h1>
      <p class="tagline">カタログではなく、共生を。</p>
      <p class="promise">
        季節・生態・記憶がつながる、生きた森の生活シミュレーション。
        あなたは所有者ではなく、森の一員です。
      </p>
      <form class="title-form" id="enter-form">
        <label for="forest-name">この森の名を呼ぶ</label>
        <input id="forest-name" name="name" maxlength="24" placeholder="例：朝霧の谷" autocomplete="off" />
        <button class="btn btn-enter" type="submit">森に入る</button>
      </form>
      <div class="diff">
        <div><strong>生きた生態</strong> — 木・湿度・動物・精霊が相互に影響する。</div>
        <div><strong>森の記憶</strong> — 世話した足跡が道になり、放置は風景を変える。</div>
        <div><strong>絆</strong> — 貨幣の代わりに、森との関係性が世界を開く。</div>
      </div>
    </div>
  </section>

  <div class="hud hidden" id="hud">
    <div class="hud-top">
      <div>
        <h2 class="forest-name" id="hud-name">森</h2>
        <p class="meta" id="hud-meta">—</p>
      </div>
      <div class="meters">
        <div class="meter">
          <div class="meter-label"><span>絆</span><span id="bond-val">0</span></div>
          <div class="meter-track"><div class="meter-fill bond" id="bond-fill"></div></div>
        </div>
        <div class="meter">
          <div class="meter-label"><span>体力</span><span id="stam-val">100</span></div>
          <div class="meter-track"><div class="meter-fill stamina" id="stam-fill"></div></div>
        </div>
      </div>
    </div>

    <div class="toast hidden" id="toast"></div>

    <div class="hud-bottom">
      <div class="actions" id="actions">
        <button class="btn action" data-act="observe" type="button"><kbd>E</kbd>観察</button>
        <button class="btn action" data-act="water" type="button"><kbd>F</kbd>水をやる</button>
        <button class="btn action" data-act="plant" type="button"><kbd>G</kbd>植える</button>
        <button class="btn action" data-act="tend" type="button"><kbd>T</kbd>整える</button>
        <button class="btn action" data-act="listen" type="button"><kbd>Q</kbd>耳を澄ます</button>
        <button class="btn action" data-act="rest" type="button"><kbd>R</kbd>休む</button>
        <button class="btn action" data-act="journal" type="button"><kbd>J</kbd>日誌</button>
      </div>
      <div class="vitals" id="vitals"></div>
    </div>
  </div>

  <div class="journal hidden" id="journal">
    <div class="journal-panel">
      <h2>森の日誌</h2>
      <p class="hint">J または閉じるで戻る</p>
      <ul id="journal-list"></ul>
      <button class="btn btn-close" type="button" id="journal-close">閉じる</button>
    </div>
  </div>
`

const canvas = document.querySelector<HTMLCanvasElement>('#forest')!
const game = new Game(canvas)

function resize(): void {
  game.renderer.resize(window.innerWidth, window.innerHeight)
}
resize()
window.addEventListener('resize', resize)
game.start()

const titleEl = document.querySelector('#title')!
const hudEl = document.querySelector('#hud')!
const toastEl = document.querySelector('#toast')!
const journalEl = document.querySelector('#journal')!
const journalList = document.querySelector('#journal-list')!
const nameInput = document.querySelector<HTMLInputElement>('#forest-name')!

document.querySelector('#enter-form')!.addEventListener('submit', (e) => {
  e.preventDefault()
  game.enterForest(nameInput.value)
  titleEl.classList.add('hidden')
  hudEl.classList.remove('hidden')
  nameInput.blur()
})

const actions: Interaction[] = ['observe', 'water', 'plant', 'tend', 'listen', 'rest']

document.querySelector('#actions')!.addEventListener('click', (e) => {
  const btn = (e.target as HTMLElement).closest<HTMLButtonElement>('[data-act]')
  if (!btn || game.screen !== 'play') return
  const act = btn.dataset.act
  if (act === 'journal') {
    game.screen = 'journal'
    return
  }
  if (act && (actions as string[]).includes(act)) {
    const result = interact(game.world, act as Interaction)
    game.showToast(result.message)
  }
})

document.querySelector('#journal-close')!.addEventListener('click', () => {
  game.closeJournal()
})

window.addEventListener('keydown', (e) => {
  const key = e.key.toLowerCase()
  if ((key === 'j' || key === 'escape') && game.screen === 'journal') {
    game.closeJournal()
  }
})

function escapeHtml(s: string): string {
  return s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
}

function syncUi(): void {
  const h = game.hud()

  if (h.screen === 'play') {
    hudEl.classList.remove('hidden')
    journalEl.classList.add('hidden')
  } else if (h.screen === 'journal') {
    hudEl.classList.remove('hidden')
    journalEl.classList.remove('hidden')
    journalList.innerHTML = h.journal
      .map((line) => `<li>${escapeHtml(line)}</li>`)
      .join('')
  } else {
    hudEl.classList.add('hidden')
    journalEl.classList.add('hidden')
  }

  if (h.screen !== 'title') {
    document.querySelector('#hud-name')!.textContent = h.name
    document.querySelector('#hud-meta')!.textContent =
      `${seasonJa[h.season]} · ${weatherJa[h.weather]} · Day ${h.day} · ${clockLabel(h.timeOfDay)}`
    document.querySelector('#bond-val')!.textContent = String(h.bond)
    document.querySelector('#stam-val')!.textContent = String(h.stamina)
    ;(document.querySelector('#bond-fill') as HTMLElement).style.width =
      `${Math.min(100, h.bond)}%`
    ;(document.querySelector('#stam-fill') as HTMLElement).style.width =
      `${h.stamina}%`
    document.querySelector('#vitals')!.innerHTML =
      `活力 <strong>${h.vitality}%</strong><br/>生き物 ${h.creatures} · 種 ${h.seeds}<br/>精霊 ${h.spirits} · 道 ${h.paths} · 世話 ${h.care}`
  }

  if (h.toast) {
    toastEl.textContent = h.toast
    toastEl.classList.remove('hidden')
  } else {
    toastEl.classList.add('hidden')
  }

  requestAnimationFrame(syncUi)
}

syncUi()
nameInput.focus()
