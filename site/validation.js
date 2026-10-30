
(() => {
  const groups = [
    { title:'ASCII and width baseline', note:'Expect letters, digits, and punctuation to be legible. In a monospaced face, M, i, and 0 should advance by the same amount even though their shapes differ.', chars:[...'MWil 0123456789'] },
    { title:'Box drawing', note:'Look at corners and intersections: horizontal and vertical strokes should meet cleanly. Repeated vertical borders should stay in the same columns from row to row.', chars:Array.from({length:64},(_,i)=>String.fromCodePoint(0x2500+i)) },
    { title:'Block elements', note:'The half and quadrant blocks should fill the indicated parts of their character cell without clipping. These are Unicode block characters, separate from Nerd Fonts icons.', chars:Array.from({length:32},(_,i)=>String.fromCodePoint(0x2580+i)) },
    { title:'Sextant shapes', note:'Each symbol divides a cell into a 2-by-3 mosaic. Look for distinct filled patterns with the same apparent cell bounds. These supplemental Unicode glyphs are often missing from older fonts or fallback setups.', chars:Array.from({length:60},(_,i)=>String.fromCodePoint(0x1FB00+i)) },
    { title:'Octant shapes', note:'Each symbol divides a cell into a 2-by-4 mosaic. Look for the small patterns to remain inside a consistent cell. Terminal Unicode-width support can differ even when the font contains the glyph.', chars:Array.from({length:16},(_,i)=>String.fromCodePoint(0x1CD00+i)) },
    { title:'Nerd Fonts icon samples', note:'These are Private Use Area codepoints added by Nerd Fonts. Expect recognizable icons rather than empty space or a replacement box. The exact icon depends on the patcher version; compare codepoints and version when an expected icon is absent.', chars:[0xF015,0xF120,0xF09B,0xF121,0xF07C,0xF0C7,0xF085,0xF013,0xF002,0xF00C,0xF00D,0xF111,0xF10B,0xF17C,0xF19C,0xF1F9].map(cp=>String.fromCodePoint(cp)) },
  ];
  const diagrams = [{"title": "Mixed box drawing and shadow", "text": "┌───────────────────┐\n│  ╔═══╗ Some Text  │▒\n│  ╚═╦═╝ in the box │▒\n╞═╤══╩══╤═══════════╡▒\n│ ├──┬──┤           │▒\n│ └──┴──┘           │▒\n└───────────────────┘▒\n ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"}, {"title": "Annotated identifier alignment", "text": "         ╭─── time_mid       ╭── node\n        ╭┶─╮           ╭─────┶────╮\ne54af2ec-d381-11ee-a506-0242ac120002\n╰──┮───╯      ╰─┮╯ ╰─┮╯\ntime_hi         │    ╰── clock_sequence_and_version\n                ╰─────── time_low_and_version"}];

  let sequence=0;
  let loadGeneration=0;
  const loaded=[];
  const fontList=document.querySelector('#fontList');
  const sizeSelect=document.querySelector('#fontSize');
  const escapeHtml=value=>value.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
  function renderAnsi(text) {
    let html='', color='#e1eee7', background='#101c21', cursor=0;
    const controls=/\x1b\[([0-9;]*)m/g;
    const segment=value=>`<span style="color:${color};background-color:${background}">${escapeHtml(value)}</span>`;
    for (const match of text.matchAll(controls)) {
      html+=segment(text.slice(cursor,match.index));
      const codes=match[1].split(';').map(Number);
      for(let i=0;i<codes.length;i++) {
        if(codes[i]===0){color='#e1eee7';background='#101c21'}
        else if((codes[i]===38||codes[i]===48)&&codes[i+1]===2&&codes.length>=i+5){
          const rgb=codes.slice(i+2,i+5).map(v=>Math.max(0,Math.min(255,v)));
          if(codes[i]===38)color=`rgb(${rgb.join(',')})`;else background=`rgb(${rgb.join(',')})`;
          i+=4;
        }
      }
      cursor=match.index+match[0].length;
    }
    return html+segment(text.slice(cursor));
  }
  function cpLabel(char){const cp=char.codePointAt(0);return `U+${cp.toString(16).toUpperCase().padStart(cp>0xFFFF?5:4,'0')}`}
  function addCard(item){
    const card=document.createElement('article'); card.className='font-card'; card.dataset.face=item.face.family;
    const head=document.createElement('div'); head.className='font-head';
    const label=document.createElement('strong'); label.textContent=item.file.name;
    const remove=document.createElement('button'); remove.type='button'; remove.textContent='Remove'; remove.setAttribute('aria-label',`Remove ${item.file.name}`);
    remove.addEventListener('click',()=>{document.fonts.delete(item.face);URL.revokeObjectURL(item.url);card.remove();const at=loaded.indexOf(item);if(at>=0)loaded.splice(at,1);showEmptyIfNeeded()});
    head.append(label,remove); const body=document.createElement('div'); body.className='font-sample'; card.append(head,body); fontList.querySelector('.empty-state')?.remove(); fontList.append(card); renderCard(card,item);
  }
  function renderCard(card,item){
    const points=Number(sizeSelect.value); const size=points*4/3; const stack=`"${item.face.family}", monospace`; let html='';
    for(const group of groups){
      html+=`<h3 class="sample-title">${escapeHtml(group.title)}</h3><p class="explain">${escapeHtml(group.note)}</p><div class="glyph-grid" style="font-family:${escapeHtml(stack)};font-size:${size}px">`;
      for(const char of group.chars) html+=`<span class="glyph" title="${cpLabel(char)}">${escapeHtml(char)}<small>${cpLabel(char).replace('U+','')}</small></span>`;
      html+='</div>';
    }
    html+=`<h3 class="sample-title">Diagram alignment tests</h3><p class="explain">Inspect the joins, nested boxes, shadow column, and annotation leaders. These diagrams preserve spaces; font fallback or proportional advances can shift the columns. The identifier example tests alignment, not UUID-version semantics.</p>`;
    for (const diagram of diagrams) html+=`<h4>${escapeHtml(diagram.title)}</h4><pre class="art" style="font-family:${escapeHtml(stack)};font-size:${size}px">${escapeHtml(diagram.text)}</pre>`;
    const artwork=window.ansiGallery.find(art=>art.id===document.querySelector('#ansiArtwork').value);
    if(artwork){
      const artHtml=artwork.rows.map(row=>row.map(([text,fg,bg])=>`<span style="color:${fg};background-color:${bg}">${escapeHtml(text)}</span>`).join('')).join('\n');
      html+=`<h3 class="sample-title">${escapeHtml(artwork.title)} — ${escapeHtml(artwork.author)}</h3><p class="explain">${artwork.width} columns × ${artwork.height} rows. DOS CP437 mapped to Unicode; ANSI cursor positions and VGA colors preserved. Blink uses bright backgrounds (iCE colors). Compare edges and solid fills with the archive reference below.</p><p><a href="${artwork.file}" download>Download original ANSI</a> · <a href="${artwork.source}" target="_blank" rel="noopener">Archive attribution</a></p><pre class="art ansi-art" style="font-family:${escapeHtml(stack)};font-size:${size}px;background:#000;color:#aaa">${artHtml}</pre><details><summary>Archive reference image</summary><img src="${artwork.reference}" alt="Archive rendering of ${escapeHtml(artwork.title)} by El Guapo" style="max-width:100%;height:auto"></details>`;
    }else{
      html+=`<h3 class="sample-title">ANSI block-art test</h3><p class="explain">An original monitor and signal-flow diagram with RGB ANSI colors, fractional blocks, sextants, octants, and private-use icon samples. Compare original, patched, and Forced faces.</p><pre class="art ansi-art" style="font-family:${escapeHtml(stack)};font-size:${size}px">${renderAnsi(window.fontWorkbenchAnsi)}</pre>`;
    }
    const chars=['M','i','0','─','│','█','🬀','🬎','𜷡',''];
    const measure=document.createElement('div'); measure.style.cssText=`position:fixed;left:-10000px;top:0;white-space:pre;font-family:${stack};font-size:${size}px;visibility:hidden`;document.body.append(measure);
    const widths=chars.map(char=>{measure.textContent=char;return {char,width:measure.getBoundingClientRect().width}}); measure.remove(); const baseline=widths[0].width;
    const rows=widths.map(({char,width})=>`<tr><td><span style="font-family:${escapeHtml(stack)};font-size:${size}px">${escapeHtml(char)}</span> (${cpLabel(char)})</td><td>${width.toFixed(2)} px</td><td class="${Math.abs(width-baseline)<0.05?'same':'different'}">${Math.abs(width-baseline)<0.05?'same advance as M':'different from M'}</td></tr>`).join('');
    html+=`<h3 class="sample-title">Measured character advances</h3><p class="explain">This compares each character’s browser advance with capital M at the chosen size. A monospaced font usually gives the same advance to letters, digits, borders, and one-cell Nerd Font icons. Different values mean the glyphs occupy different horizontal space here. This is a browser pixel measurement, not a terminal-cell guarantee; a fallback glyph can affect it.</p><table class="measure"><thead><tr><th scope="col">Sample</th><th scope="col">Advance</th><th scope="col">Compared with M</th></tr></thead><tbody>${rows}</tbody></table>`;
    card.querySelector('.font-sample').innerHTML=html;
  }
  function showEmptyIfNeeded(){if(!fontList.querySelector('.font-card'))fontList.innerHTML='<div class="empty-state">No fonts selected yet. Browse for one or more TTF/OTF files to start the side by side comparison.</div>'}
  document.querySelector('#fontFiles').addEventListener('change',async event=>{
    const status=document.querySelector("#loadStatus");
    const generation=loadGeneration;
    for(const file of Array.from(event.target.files||[])){
      status.textContent=`Loading ${file.name}…`;
      const internalName=`NerdValidationFont${++sequence}`; const url=URL.createObjectURL(file); const face=new FontFace(internalName,`url("${url}")`);
      try{await face.load();if(generation!==loadGeneration){URL.revokeObjectURL(url);break}document.fonts.add(face);const item={file,face,url};loaded.push(item);addCard(item);status.textContent=`Loaded ${file.name}. ${loaded.length} font(s) selected.`}
      catch(error){URL.revokeObjectURL(url);status.textContent=`Could not load ${file.name}: ${error.message}`}
    }
    event.target.value='';
  });
  document.querySelector('#clearFonts').addEventListener('click',()=>{loadGeneration++;for(const item of [...loaded]){document.fonts.delete(item.face);URL.revokeObjectURL(item.url)}loaded.length=0;document.querySelector('#loadStatus').textContent='Selected fonts cleared.';fontList.innerHTML='<div class="empty-state">No fonts selected yet. Browse for one or more TTF/OTF files to start the side by side comparison.</div>'});
  document.querySelector('#ansiArtwork').addEventListener('change',()=>document.querySelectorAll('.font-card').forEach((card,index)=>renderCard(card,loaded[index])));
  sizeSelect.addEventListener('change',()=>document.querySelectorAll('.font-card').forEach((card,index)=>renderCard(card,loaded[index])));
})();
