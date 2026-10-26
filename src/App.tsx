import { useState } from 'react';
import {
  Activity, AlertTriangle, Bell, BriefcaseBusiness, CarFront, ChartNoAxesCombined,
  CheckCircle2, ChevronDown, ClipboardList, Clock3, FileText, Gauge, Menu,
  Search, Settings, ShieldAlert, Truck, Users, Wrench, Wallet, X,
} from 'lucide-react';

type NavItem = { label: string; icon: typeof Gauge };

const navItems: NavItem[] = [
  { label: 'Dashboard', icon: Gauge },
  { label: 'Sinistros', icon: ClipboardList },
  { label: 'Pendências', icon: Bell },
  { label: 'Veículos', icon: Truck },
  { label: 'Motoristas', icon: Users },
  { label: 'Seguradoras', icon: ShieldAlert },
  { label: 'Oficina', icon: Wrench },
  { label: 'Indicadores', icon: ChartNoAxesCombined },
  { label: 'Relatórios', icon: FileText },
  { label: 'Configurações', icon: Settings },
];

const metrics = [
  { label: 'Sinistros abertos', value: '—', note: 'Aguardando conexão com o banco', icon: ClipboardList, tone: 'green' },
  { label: 'Atrasados', value: '—', note: 'Exigem ação imediata', icon: AlertTriangle, tone: 'red' },
  { label: 'Vencendo hoje', value: '—', note: 'Prazos do dia', icon: Clock3, tone: 'orange' },
  { label: 'Veículos parados', value: '—', note: 'Em reparo ou imobilizados', icon: CarFront, tone: 'blue' },
  { label: 'Valores a cobrar', value: 'R$ —', note: 'Cobranças definidas', icon: Wallet, tone: 'purple' },
  { label: 'Valores recebidos', value: 'R$ —', note: 'Pagamentos registrados', icon: CheckCircle2, tone: 'green' },
];

function App() {
  const [active, setActive] = useState('Dashboard');
  const [search, setSearch] = useState('');
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <div className="app-shell">
      <aside className={`sidebar ${menuOpen ? 'sidebar-open' : ''}`}>
        <div className="brand">
          <div className="brand-mark"><Truck size={23} /></div>
          <div><strong>CONTROLE DE</strong><strong>SINISTROS</strong><span>GESTÃO DE FROTA</span></div>
          <button className="icon-button mobile-close" onClick={() => setMenuOpen(false)} aria-label="Fechar menu"><X size={18} /></button>
        </div>
        <div className="nav-caption">OPERAÇÃO</div>
        <nav>
          {navItems.map(({ label, icon: Icon }) => (
            <button key={label} className={`nav-item ${active === label ? 'active' : ''}`} onClick={() => { setActive(label); setMenuOpen(false); }}>
              <Icon size={18} strokeWidth={1.8} /><span>{label}</span>{label === 'Pendências' && <span className="nav-dot" />}
            </button>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="status-mark"><Activity size={16} /><span>Central de controle</span></div>
          <p>Princípio operacional</p>
          <blockquote>Nenhum sinistro sem responsável, prazo, próxima ação ou histórico.</blockquote>
        </div>
      </aside>

      {menuOpen && <button className="backdrop" aria-label="Fechar menu" onClick={() => setMenuOpen(false)} />}

      <main className="main-area">
        <header className="topbar">
          <div className="topbar-left">
            <button className="icon-button mobile-menu" onClick={() => setMenuOpen(true)} aria-label="Abrir menu"><Menu size={21} /></button>
            <div className="breadcrumb">Operação <span>/</span> <strong>{active}</strong></div>
          </div>
          <div className="topbar-actions">
            <label className="global-search"><Search size={17} /><input value={search} onChange={e => setSearch(e.target.value)} placeholder="Buscar sinistro, placa, motorista..." /></label>
            <button className="icon-button notification-button" aria-label="Notificações"><Bell size={19} /><i /></button>
            <button className="profile-button"><span className="avatar">GF</span><span className="profile-copy"><strong>Gestão de Frota</strong><small>Perfil demonstrativo</small></span><ChevronDown size={15} /></button>
          </div>
        </header>

        <div className="page-content">
          <section className="welcome-row">
            <div>
              <div className="eyebrow"><span className="live-dot" /> TORRE DE CONTROLE</div>
              <h1>CONTROLE DE SINISTROS</h1>
              <p className="subtitle">Visão operacional da frota, prazos e ações prioritárias.</p>
            </div>
            <button className="primary-button" onClick={() => setActive('Sinistros')}><ClipboardList size={17} /> Novo sinistro</button>
          </section>

          <div className="notice"><div className="notice-icon"><ShieldAlert size={19} /></div><div><strong>Ambiente inicial — dados ainda não conectados</strong><p>Esta tela é a base visual do sistema. Os indicadores serão alimentados pelo banco de dados após a configuração de autenticação e Supabase.</p></div></div>

          <section className="section-heading"><div><h2>Visão geral</h2><p>Acompanhe os principais indicadores da operação.</p></div><button className="period-button">Visão geral <ChevronDown size={15} /></button></section>
          <div className="metrics-grid">
            {metrics.map(({ label, value, note, icon: Icon, tone }) => (
              <article className="metric-card" key={label}>
                <div className="metric-top"><span>{label}</span><span className={`metric-icon ${tone}`}><Icon size={19} /></span></div>
                <div className="metric-value">{value}</div><p>{note}</p>
              </article>
            ))}
          </div>

          <section className="section-heading action-heading"><div><h2><AlertTriangle size={19} /> Ação necessária hoje</h2><p>Prioridades que precisam de acompanhamento da gestão.</p></div><span className="count-pill">Aguardando dados</span></section>
          <div className="empty-state">
            <div className="empty-icon"><CheckCircle2 size={25} /></div>
            <strong>Nenhuma ocorrência carregada</strong>
            <p>Quando o banco estiver conectado, aparecerão aqui sinistros atrasados, prazos vencendo, falta de movimentação, ações pendentes e documentação incompleta.</p>
          </div>

          <section className="lower-grid">
            <article className="panel">
              <div className="panel-heading"><div><h3>Fluxo de atendimento</h3><p>Etapas padrão do sinistro</p></div><BriefcaseBusiness size={19} /></div>
              <div className="stage-list">{['Ocorrência', 'Comunicação', 'Abertura', 'Documentação', 'Vistoria da seguradora', 'Autorização', 'Oficina e reparo', 'Entrega', 'Financeiro', 'Encerramento'].map((stage, i) => <div className="stage" key={stage}><span className={i === 0 ? 'stage-number stage-current' : 'stage-number'}>{String(i + 1).padStart(2, '0')}</span><span>{stage}</span><span className="stage-line" /></div>)}</div>
            </article>
            <article className="panel">
              <div className="panel-heading"><div><h3>Regras de controle</h3><p>Padrões operacionais previstos</p></div><Settings size={19} /></div>
              <div className="rule-list">
                <div className="rule"><span className="rule-icon red"><AlertTriangle size={17} /></span><div><strong>Prazo vencido</strong><p>Alerta crítico para ações fora do prazo.</p></div></div>
                <div className="rule"><span className="rule-icon orange"><Clock3 size={17} /></span><div><strong>Sem movimentação há 2 dias</strong><p>Sinistros sem atualização entram na fila de atenção.</p></div></div>
                <div className="rule"><span className="rule-icon green"><CheckCircle2 size={17} /></span><div><strong>Responsabilidade definida</strong><p>Sinistro ativo exige responsável, prazo e próxima ação.</p></div></div>
                <div className="rule"><span className="rule-icon blue"><Wallet size={17} /></span><div><strong>Financeiro separado</strong><p>Custo real do reparo não se confunde com cobrança ao motorista.</p></div></div>
              </div>
            </article>
          </section>
          <footer>CONTROLE DE SINISTROS <span>•</span> Estrutura inicial do sistema <span>•</span> Não utilizar ainda para registros reais</footer>
        </div>
      </main>
    </div>
  );
}

export default App;