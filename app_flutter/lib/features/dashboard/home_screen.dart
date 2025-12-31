import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _balanceCard(BuildContext c) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saldo Disponível', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('R\$ 243,50', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check),
                label: const Text('Resgatar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
            const SizedBox(width: 8),
            Text('Adiantado: R\$ 50,00', style: TextStyle(color: Colors.white70)),
            const SizedBox(width: 16),
            const Icon(Icons.fiber_manual_record, color: Colors.orange, size: 12),
            const SizedBox(width: 8),
            Text('Pendente: R\$ 120,00', style: TextStyle(color: Colors.white70)),
          ])
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade800,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('Olá, Marcos!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Seu Cashback Sem Espera!', style: TextStyle(color: Colors.white70))
                    ]),
                    CircleAvatar(radius: 22, backgroundColor: Colors.grey)
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _balanceCard(context),
              // Placeholder for offers
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blueGrey.shade700, borderRadius: BorderRadius.circular(12)),
                child: Row(children: const [Icon(Icons.receipt_long), SizedBox(width: 8), Text('Oferta Instantânea!')]),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Atividades Recentes', style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 12),
              // Recent activities list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blueGrey.shade900, borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                        Text('Cashback Adiantado', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Pagamento Farmácia', style: TextStyle(color: Colors.white70))
                      ]),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: const [
                        Text('R\$ 15,00', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Recebido agora', style: TextStyle(color: Colors.greenAccent))
                      ])
                    ]),
                  );
                },
              ),
              const SizedBox(height: 80)
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
        BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Ofertas'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Escanear'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Carteira'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil')
      ]),
    );
  }
}
