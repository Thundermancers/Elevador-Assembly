# Elevador-Assembly

## Introdução
Esse projeto foi implementado por conta das disciplinas de *INSTRUMENTAÇÃO ELETRÔNICA* e *MICROCONTROLADORES E APLICAÇÕES*. O projeto diz respeito a implementação de um mini elevador. O projeto teve duas partes: uma desenvolvida em assembly, a qual não leva em consideração a parte física do elevador, e a outra parte foi desenvolvida em *ino* e leva em consideração a parte física do elevador. Em assembly simulamos que o movimento do elevador é de 3s de um andar para o outro.

## Requisitos
### Assembly
#### Estrutura
Os requisitos com relação a estrutura são:
* Ter um Térreo mais 3 andares;
* Ter botões dentro da cabine do elevador para mover o elevador;
* Um botão dentro do elevador para abrir a porta;
* Um botão dentro do elevador para fechar a porta;
* Um buzzer para avisar que a porta ta aberta;
* Ter botões que correspondem as chamada do elevador em cada andar;
* Um display de 7 segmentos para cada andar e dentro do elevador, que indicará o andar atual;
* Utilizar um LED para indicar o estado da porta(aberto ou fechado)
#### Funcionamento
Os requisitos com relação ao funcionamento são:
* Priorizar os andares mais altos;
  ** Por exemplo: Se estiver no térreo subindo para o 4º andar, não deve parar no 2º andar, mesmo que o botão que fica no segundo andar tenha sido pressionado antes de o carro do elevador passar pelo 2° andar.
* Se a porta do elevador ficar aberta por 5 segundos, toca-se o Buzzer;
* Se a porta do elevador ficar aberta por 10s, a porta é automaticamente fechada;
* O elevador leva 3 segundos de um andar para o outro.
* Enviar log pela serial

### Arduino
#### Estrutura
Os requisitos com relação a estrutura são:
* Ter um Térreo mais 3 andares;
* Ter botões dentro da cabine do elevador para mover o elevador;
* Um botão dentro do elevador para abrir e fechar a porta;
* Ter botões que correspondem as chamada do elevador em cada andar;
* Utilizar um display de 7 segmentos para indicar o andar atual;
* Utilizar um LED para indicar o estado da porta(aberto ou fechado)
* Utilizar um LCD para mostrar o log do sistema
#### Funcionamento
Os requisitos com relação ao funcionamento são:
* Priorizar os andares mais altos;
** Por exemplo: Se estiver no térreo subindo para o 4º andar, não deve parar no 2º andar, mesmo que o botão que fica no segundo andar tenha sido pressionado antes de o carro do elevador passar pelo 2° andar.
* Se a porta do elevador ficar aberta por 10s, a porta é automaticamente fechada.
* Enviar log pela serial

## Vídeos
### Assembly
[Video do funcionamento do elevador em assembly](https://www.youtube.com/watch?v=NJsJVgUABao&feature=youtu.be)
### Arduino
[Video do funcionamento do elevador em arduino](https://youtu.be/CorqOT0HRPI)

## Imagens
### Arduino
![](/imgs/lcd1.jpg = 100px)
![](/imgs/lcd2.jpg = 100px)
![](/imgs/lcd3.jpg = 100px)
