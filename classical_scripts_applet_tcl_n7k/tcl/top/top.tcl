#
# Copyright (c) 2012 Scott Tudor <netc.project@gmail.com>
# All rights reserved.
#
# Limitation of Liability
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY.
#
# IN NO EVENT, REGARDLESS OF CAUSE, SHALL THE AUTHOR OF THIS SCRIPT BE LIABLE
# FOR ANY INDIRECT, SPECIAL, INCIDENTAL, PUNITIVE OR CONSEQUENTIAL DAMAGES OF ANY
# KIND, WHETHER ARISING UNDER BREACH OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
# STRICT LIABILITY OR OTHERWISE, AND WHETHER BASED ON THIS AGREEMENT OR 
# OTHERWISE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.


::cisco::eem::event_register_none nice 1 maxrun 700 default 700


namespace import ::cisco::eem::*
namespace import ::cisco::lib::*



#######
proc callwait {refresh2} { 
  for {set j 0} {$j < $refresh2} {incr j }  {after 990} 
}
#######
proc Dirn {dirn2} {
switch $dirn2 {
 Input  {return "IN "}
 Output {return "OUT"}
 default {return "NA"}}
}
######
proc printHelp {} {
 puts {Usage:   top <arg1> }
 puts {		-h                  HELP with options}
 puts {		-f <flowMonName>    FLOW monitor name, default=Cfg first listed}
 puts {		-r <sec>     	    REFRESH rate [1..30]; default 7}
}
######
proc CnvrtPortNum {portnum2 protnum2} {

if {!([string equal $protnum2 6] || [string equal $protnum2 17])} {return $portnum2}

if [string equal $protnum2 6] { 
switch $portnum2 {
0 {return 0-spl-itunes}
1 {return 1-tcpmux}
2 {return 2-compressnet}
3 {return 3-compressnet}
5 {return 5-rje}
7 {return 7-echo}
9 {return 9-discard}
11 {return 11-systat}
13 {return 13-daytime}
17 {return 17-qotd}
18 {return 18-msp}
19 {return 19-chargen}
20 {return 20-ftp-data}
21 {return 21-ftp}
22 {return 22-ssh}
23 {return 23-telnet}
24 {return 24-privmail}
25 {return 25-smtp}
27 {return 27-nsw-fe}
29 {return 29-msg-icp}
31 {return 31-msg-auth}
33 {return 33-dsp}
35 {return 35-prvprtsvr}
37 {return 37-time}
38 {return 38-rap}
39 {return 39-rlp}
41 {return 41-graphics}
42 {return 42-name}
43 {return 43-nicname}
44 {return 44-mpm-flags}
45 {return 45-mpm}
46 {return 46-mpm-snd}
47 {return 47-ni-ftp}
48 {return 48-auditd}
49 {return 49-tacacs}
50 {return 50-re-mail-ck}
51 {return 51-la-maint}
52 {return 52-xns-time}
53 {return 53-domain}
54 {return 54-xns-ch}
55 {return 55-isi-gl}
56 {return 56-xns-auth}
57 {return 57-prvtrmacc}
58 {return 58-xns-mail}
59 {return 59-prvfiler}
61 {return 61-ni-mail}
62 {return 62-acas}
63 {return 63-whois++}
64 {return 64-covia}
65 {return 65-tacacs-ds}
66 {return 66-sql*net}
67 {return 67-bootps}
68 {return 68-bootpc}
69 {return 69-tftp}
70 {return 70-gopher}
71 {return 71-netrjs-1}
72 {return 72-netrjs-2}
73 {return 73-netrjs-3}
74 {return 74-netrjs-4}
75 {return 75-prvdialer}
76 {return 76-deos}
77 {return 77-prvRJE}
78 {return 78-vettcp}
79 {return 79-finger}
80 {return 80-http}
82 {return 82-xfer}
83 {return 83-mit-ml-dev}
84 {return 84-ctf}
85 {return 85-mit-ml-dev}
86 {return 86-mfcobol}
87 {return 87-prvtermlnk}
88 {return 88-kerberos}
89 {return 89-su-mit-tg}
90 {return 90-dnsix}
91 {return 91-mit-dov}
92 {return 92-npp}
93 {return 93-dcp}
94 {return 94-objcall}
95 {return 95-supdup}
96 {return 96-dixie}
97 {return 97-swift-rvf}
98 {return 98-tacnews}
99 {return 99-metagram}
100 {return 100-newacct}
101 {return 101-hostname}
102 {return 102-iso-tsap}
103 {return 103-gppitnp}
104 {return 104-acr-nema}
105 {return 105-csnet-ns}
106 {return 106-3com-tsmux}
107 {return 107-rtelnet}
108 {return 108-snagas}
109 {return 109-pop2}
110 {return 110-pop3}
111 {return 111-sunrpc}
112 {return 112-mcidas}
113 {return 113-auth}
115 {return 115-sftp}
116 {return 116-ansanotify}
117 {return 117-uucp-path}
118 {return 118-sqlserv}
119 {return 119-nntp}
120 {return 120-cfdptkt}
121 {return 121-erpc}
122 {return 122-smakynet}
123 {return 123-ntp}
124 {return 124-ansatrader}
125 {return 125-locus-map}
126 {return 126-nxedit}
127 {return 127-locus-con}
128 {return 128-gss-xlicen}
129 {return 129-pwdgen}
130 {return 130-cisco-fna}
131 {return 131-cisco-tna}
132 {return 132-cisco-sys}
133 {return 133-statsrv}
134 {return 134-ingres-net}
135 {return 135-epmap}
136 {return 136-profile}
137 {return 137-netbios-ns}
138 {return 138-netbios-dgm}
139 {return 139-netbios-ssn}
140 {return 140-emfis-data}
141 {return 141-emfis-cntl}
142 {return 142-bl-idm}
143 {return 143-imap}
144 {return 144-uma}
145 {return 145-uaac}
146 {return 146-iso-tp0}
147 {return 147-iso-ip}
148 {return 148-jargon}
149 {return 149-aed-512}
150 {return 150-sql-net}
151 {return 151-hems}
152 {return 152-bftp}
153 {return 153-sgmp}
154 {return 154-netsc-prod}
155 {return 155-netsc-dev}
156 {return 156-sqlsrv}
157 {return 157-knet-cmp}
158 {return 158-pcmail-srv}
159 {return 159-nss-routing}
160 {return 160-sgmp-traps}
161 {return 161-snmp}
162 {return 162-snmptrap}
163 {return 163-cmip-man}
164 {return 164-cmip-agent}
165 {return 165-xns-courier}
166 {return 166-s-net}
167 {return 167-namp}
168 {return 168-rsvd}
169 {return 169-send}
170 {return 170-print-srv}
171 {return 171-multiplex}
172 {return 172-cl/1}
173 {return 173-xyplex-mux}
174 {return 174-mailq}
175 {return 175-vmnet}
176 {return 176-genrad-mux}
177 {return 177-xdmcp}
178 {return 178-nextstep}
179 {return 179-bgp}
180 {return 180-ris}
181 {return 181-unify}
182 {return 182-audit}
183 {return 183-ocbinder}
184 {return 184-ocserver}
185 {return 185-remote-kis}
186 {return 186-kis}
187 {return 187-aci}
188 {return 188-mumps}
189 {return 189-qft}
190 {return 190-gacp}
191 {return 191-prospero}
192 {return 192-osu-nms}
193 {return 193-srmp}
194 {return 194-irc}
195 {return 195-dn6-nlm-aud}
196 {return 196-dn6-smm-red}
197 {return 197-dls}
198 {return 198-dls-mon}
199 {return 199-smux}
200 {return 200-src}
201 {return 201-at-rtmp}
202 {return 202-at-nbp}
203 {return 203-at-3}
204 {return 204-at-echo}
205 {return 205-at-5}
206 {return 206-at-zis}
207 {return 207-at-7}
208 {return 208-at-8}
209 {return 209-qmtp}
210 {return 210-z39.50}
211 {return 211-914c/g}
212 {return 212-anet}
213 {return 213-ipx}
214 {return 214-vmpwscs}
215 {return 215-softpc}
216 {return 216-CAIlic}
217 {return 217-dbase}
218 {return 218-mpp}
219 {return 219-uarps}
220 {return 220-imap3}
221 {return 221-fln-spx}
222 {return 222-rsh-spx}
223 {return 223-cdc}
224 {return 224-masqdialer}
242 {return 242-direct}
243 {return 243-sur-meas}
244 {return 244-inbusiness}
245 {return 245-link}
246 {return 246-dsp3270}
247 {return 247-subntbcst_tftp}
248 {return 248-bhfhs}
256 {return 256-rap}
257 {return 257-set}
259 {return 259-esro-gen}
260 {return 260-openport}
261 {return 261-nsiiops}
262 {return 262-arcisdms}
263 {return 263-hdap}
264 {return 264-bgmp}
265 {return 265-x-bone-ctl}
266 {return 266-sst}
267 {return 267-td-service}
268 {return 268-td-replica}
269 {return 269-manet}
280 {return 280-http-mgmt}
281 {return 281-personal-link}
282 {return 282-cableport-ax}
283 {return 283-rescap}
284 {return 284-corerjd}
286 {return 286-fxp}
287 {return 287-k-block}
308 {return 308-novastorbakcup}
309 {return 309-entrusttime}
310 {return 310-bhmds}
311 {return 311-asip-webadmin}
312 {return 312-vslmp}
313 {return 313-magenta-logic}
314 {return 314-opalis-robot}
315 {return 315-dpsi}
316 {return 316-decauth}
317 {return 317-zannet}
318 {return 318-pkix-timestamp}
319 {return 319-ptp-event}
320 {return 320-ptp-general}
321 {return 321-pip}
322 {return 322-rtsps}
333 {return 333-texar}
344 {return 344-pdap}
345 {return 345-pawserv}
346 {return 346-zserv}
347 {return 347-fatserv}
348 {return 348-csi-sgwp}
349 {return 349-mftp}
350 {return 350-matip-type-a}
351 {return 351-matip-type-b}
352 {return 352-dtag-ste-sb}
353 {return 353-ndsauth}
354 {return 354-bh611}
355 {return 355-datex-asn}
356 {return 356-cloanto-net-1}
357 {return 357-bhevent}
358 {return 358-shrinkwrap}
359 {return 359-nsrmp}
360 {return 360-scoi2odialog}
361 {return 361-semantix}
362 {return 362-srssend}
363 {return 363-rsvp_tunnel}
364 {return 364-aurora-cmgr}
365 {return 365-dtk}
366 {return 366-odmr}
367 {return 367-mortgageware}
368 {return 368-qbikgdp}
369 {return 369-rpc2portmap}
370 {return 370-codaauth2}
371 {return 371-clearcase}
372 {return 372-ulistproc}
373 {return 373-legent-1}
374 {return 374-legent-2}
375 {return 375-hassle}
376 {return 376-nip}
377 {return 377-tnETOS}
378 {return 378-dsETOS}
379 {return 379-is99c}
380 {return 380-is99s}
381 {return 381-hp-collector}
382 {return 382-hp-managed-node}
383 {return 383-hp-alarm-mgr}
384 {return 384-arns}
385 {return 385-ibm-app}
386 {return 386-asa}
387 {return 387-aurp}
388 {return 388-unidata-ldm}
389 {return 389-ldap}
390 {return 390-uis}
391 {return 391-synotics-relay}
392 {return 392-synotics-broker}
393 {return 393-meta5}
394 {return 394-embl-ndt}
395 {return 395-netcp}
396 {return 396-netware-ip}
397 {return 397-mptn}
398 {return 398-kryptolan}
399 {return 399-iso-tsap-c2}
400 {return 400-osb-sd}
401 {return 401-ups}
402 {return 402-genie}
403 {return 403-decap}
404 {return 404-nced}
405 {return 405-ncld}
406 {return 406-imsp}
407 {return 407-timbuktu}
408 {return 408-prm-sm}
409 {return 409-prm-nm}
410 {return 410-decladebug}
411 {return 411-rmt}
412 {return 412-synoptics-trap}
413 {return 413-smsp}
414 {return 414-infoseek}
415 {return 415-bnet}
416 {return 416-silverplatter}
417 {return 417-onmux}
418 {return 418-hyper-g}
419 {return 419-ariel1}
420 {return 420-smpte}
421 {return 421-ariel2}
422 {return 422-ariel3}
423 {return 423-opc-job-start}
424 {return 424-opc-job-track}
425 {return 425-icad-el}
426 {return 426-smartsdp}
427 {return 427-svrloc}
428 {return 428-ocs_cmu}
429 {return 429-ocs_amu}
430 {return 430-utmpsd}
431 {return 431-utmpcd}
432 {return 432-iasd}
433 {return 433-nnsp}
434 {return 434-mobileip-agent}
435 {return 435-mobilip-mn}
436 {return 436-dna-cml}
437 {return 437-comscm}
438 {return 438-dsfgw}
439 {return 439-dasp}
440 {return 440-sgcp}
441 {return 441-decvms-sysmgt}
442 {return 442-cvc_hostd}
443 {return 443-https}
444 {return 444-snpp}
445 {return 445-microsoft-ds}
446 {return 446-ddm-rdb}
447 {return 447-ddm-dfm}
448 {return 448-ddm-ssl}
449 {return 449-as-servermap}
450 {return 450-tserver}
451 {return 451-sfs-smp-net}
452 {return 452-sfs-config}
453 {return 453-creativeserver}
454 {return 454-contentserver}
455 {return 455-creativepartnr}
456 {return 456-macon-tcp}
457 {return 457-scohelp}
458 {return 458-appleqtc}
459 {return 459-ampr-rcmd}
460 {return 460-skronk}
461 {return 461-datasurfsrv}
462 {return 462-datasurfsrvsec}
463 {return 463-alpes}
464 {return 464-kpasswd}
465 {return 465-urd}
466 {return 466-digital-vrc}
467 {return 467-mylex-mapd}
468 {return 468-photuris}
469 {return 469-rcp}
470 {return 470-scx-proxy}
471 {return 471-mondex}
472 {return 472-ljk-login}
473 {return 473-hybrid-pop}
474 {return 474-tn-tl-w1}
475 {return 475-tcpnethaspsrv}
476 {return 476-tn-tl-fd1}
477 {return 477-ss7ns}
478 {return 478-spsc}
479 {return 479-iafserver}
480 {return 480-iafdbase}
481 {return 481-ph}
482 {return 482-bgs-nsi}
483 {return 483-ulpnet}
484 {return 484-integra-sme}
485 {return 485-powerburst}
486 {return 486-avian}
487 {return 487-saft}
488 {return 488-gss-http}
489 {return 489-nest-protocol}
490 {return 490-micom-pfs}
491 {return 491-go-login}
492 {return 492-ticf-1}
493 {return 493-ticf-2}
494 {return 494-pov-ray}
495 {return 495-intecourier}
496 {return 496-pim-rp-disc}
497 {return 497-dantz}
498 {return 498-siam}
499 {return 499-iso-ill}
500 {return 500-isakmp}
501 {return 501-stmf}
502 {return 502-asa-appl-proto}
503 {return 503-intrinsa}
504 {return 504-citadel}
505 {return 505-mailbox-lm}
506 {return 506-ohimsrv}
507 {return 507-crs}
508 {return 508-xvttp}
509 {return 509-snare}
510 {return 510-fcp}
511 {return 511-passgo}
512 {return 512-exec}
513 {return 513-login}
514 {return 514-shell}
515 {return 515-printer}
516 {return 516-videotex}
517 {return 517-talk}
518 {return 518-ntalk}
519 {return 519-utime}
520 {return 520-efs}
521 {return 521-ripng}
522 {return 522-ulp}
523 {return 523-ibm-db2}
524 {return 524-ncp}
525 {return 525-timed}
526 {return 526-tempo}
527 {return 527-stx}
528 {return 528-custix}
529 {return 529-irc-serv}
530 {return 530-courier}
531 {return 531-conference}
532 {return 532-netnews}
533 {return 533-netwall}
534 {return 534-windream}
535 {return 535-iiop}
536 {return 536-opalis-rdv}
537 {return 537-nmsp}
538 {return 538-gdomap}
539 {return 539-apertus-ldp}
540 {return 540-uucp}
541 {return 541-uucp-rlogin}
542 {return 542-commerce}
543 {return 543-klogin}
544 {return 544-kshell}
545 {return 545-appleqtcsrvr}
546 {return 546-dhcpv6-client}
547 {return 547-dhcpv6-server}
548 {return 548-afpovertcp}
549 {return 549-idfp}
550 {return 550-new-rwho}
551 {return 551-cybercash}
552 {return 552-devshr-nts}
553 {return 553-pirp}
554 {return 554-rtsp}
555 {return 555-dsf}
556 {return 556-remotefs}
557 {return 557-openvms-sysipc}
558 {return 558-sdnskmp}
559 {return 559-teedtap}
560 {return 560-rmonitor}
561 {return 561-monitor}
562 {return 562-chshell}
563 {return 563-nntps}
564 {return 564-9pfs}
565 {return 565-whoami}
566 {return 566-streettalk}
567 {return 567-banyan-rpc}
568 {return 568-ms-shuttle}
569 {return 569-ms-rome}
570 {return 570-meter}
571 {return 571-meter}
572 {return 572-sonar}
573 {return 573-banyan-vip}
574 {return 574-ftp-agent}
575 {return 575-vemmi}
576 {return 576-ipcd}
577 {return 577-vnas}
578 {return 578-ipdd}
579 {return 579-decbsrv}
580 {return 580-sntp-heartbeat}
581 {return 581-bdp}
582 {return 582-scc-security}
583 {return 583-philips-vc}
584 {return 584-keyserver}
586 {return 586-password-chg}
587 {return 587-submission}
588 {return 588-cal}
589 {return 589-eyelink}
590 {return 590-tns-cml}
591 {return 591-http-alt}
592 {return 592-eudora-set}
593 {return 593-http-rpc-epmap}
594 {return 594-tpip}
595 {return 595-cab-protocol}
596 {return 596-smsd}
597 {return 597-ptcnameservice}
598 {return 598-sco-websrvrmg3}
599 {return 599-acp}
600 {return 600-ipcserver}
601 {return 601-syslog-conn}
602 {return 602-xmlrpc-beep}
603 {return 603-idxp}
604 {return 604-tunnel}
605 {return 605-soap-beep}
606 {return 606-urm}
607 {return 607-nqs}
608 {return 608-sift-uft}
609 {return 609-npmp-trap}
610 {return 610-npmp-local}
611 {return 611-npmp-gui}
612 {return 612-hmmp-ind}
613 {return 613-hmmp-op}
614 {return 614-sshell}
615 {return 615-sco-inetmgr}
616 {return 616-sco-sysmgr}
617 {return 617-sco-dtmgr}
618 {return 618-dei-icda}
619 {return 619-compaq-evm}
620 {return 620-sco-websrvrmgr}
621 {return 621-escp-ip}
622 {return 622-collaborator}
623 {return 623-oob-ws-http}
624 {return 624-cryptoadmin}
625 {return 625-dec_dlm}
626 {return 626-asia}
627 {return 627-passgo-tivoli}
628 {return 628-qmqp}
629 {return 629-3com-amp3}
630 {return 630-rda}
631 {return 631-ipp}
632 {return 632-bmpp}
633 {return 633-servstat}
634 {return 634-ginad}
635 {return 635-rlzdbase}
636 {return 636-ldaps}
637 {return 637-lanserver}
638 {return 638-mcns-sec}
639 {return 639-msdp}
640 {return 640-entrust-sps}
641 {return 641-repcmd}
642 {return 642-esro-emsdp}
643 {return 643-sanity}
644 {return 644-dwr}
645 {return 645-pssc}
646 {return 646-ldp}
647 {return 647-dhcp-failover}
648 {return 648-rrp}
649 {return 649-cadview-3d}
650 {return 650-obex}
651 {return 651-ieee-mms}
652 {return 652-hello-port}
653 {return 653-repscmd}
654 {return 654-aodv}
655 {return 655-tinc}
656 {return 656-spmp}
657 {return 657-rmc}
658 {return 658-tenfold}
660 {return 660-mac-srvr-admin}
661 {return 661-hap}
662 {return 662-pftp}
663 {return 663-purenoise}
664 {return 664-oob-ws-https}
665 {return 665-sun-dr}
666 {return 666-doom}
667 {return 667-disclose}
668 {return 668-mecomm}
669 {return 669-meregister}
670 {return 670-vacdsm-sws}
671 {return 671-vacdsm-app}
672 {return 672-vpps-qua}
673 {return 673-cimplex}
674 {return 674-acap}
675 {return 675-dctp}
676 {return 676-vpps-via}
677 {return 677-vpp}
678 {return 678-ggf-ncp}
679 {return 679-mrm}
680 {return 680-entrust-aaas}
681 {return 681-entrust-aams}
682 {return 682-xfr}
683 {return 683-corba-iiop}
684 {return 684-corba-iiop-ssl}
685 {return 685-mdc-portmapper}
686 {return 686-hcp-wismar}
687 {return 687-asipregistry}
688 {return 688-realm-rusd}
689 {return 689-nmap}
690 {return 690-vatp}
691 {return 691-msexch-routing}
692 {return 692-hyperwave-isp}
693 {return 693-connendp}
694 {return 694-ha-cluster}
695 {return 695-ieee-mms-ssl}
696 {return 696-rushd}
697 {return 697-uuidgen}
698 {return 698-olsr}
699 {return 699-accessnetwork}
700 {return 700-epp}
701 {return 701-lmp}
702 {return 702-iris-beep}
704 {return 704-elcsd}
705 {return 705-agentx}
706 {return 706-silc}
707 {return 707-borland-dsj}
709 {return 709-entrust-kmsh}
710 {return 710-entrust-ash}
711 {return 711-cisco-tdp}
712 {return 712-tbrpf}
713 {return 713-iris-xpc}
714 {return 714-iris-xpcs}
715 {return 715-iris-lwz}
729 {return 729-netviewdm1}
730 {return 730-netviewdm2}
731 {return 731-netviewdm3}
741 {return 741-netgw}
742 {return 742-netrcs}
744 {return 744-flexlm}
747 {return 747-fujitsu-dev}
748 {return 748-ris-cm}
749 {return 749-kerberos-adm}
750 {return 750-rfile}
751 {return 751-pump}
752 {return 752-qrh}
753 {return 753-rrh}
754 {return 754-tell}
758 {return 758-nlogin}
759 {return 759-con}
760 {return 760-ns}
761 {return 761-rxe}
762 {return 762-quotad}
763 {return 763-cycleserv}
764 {return 764-omserv}
765 {return 765-webster}
767 {return 767-phonebook}
769 {return 769-vid}
770 {return 770-cadlock}
771 {return 771-rtip}
772 {return 772-cycleserv2}
773 {return 773-submit}
774 {return 774-rpasswd}
775 {return 775-entomb}
776 {return 776-wpages}
777 {return 777-multiling-http}
780 {return 780-wpgs}
800 {return 800-mdbs_daemon}
801 {return 801-device}
810 {return 810-fcp-udp}
828 {return 828-itm-mcell-s}
829 {return 829-pkix-3-ca-ra}
830 {return 830-netconf-ssh}
831 {return 831-netconf-beep}
832 {return 832-netconfsoaphttp}
833 {return 833-netconfsoapbeep}
847 {return 847-dhcp-failover2}
848 {return 848-gdoi}
860 {return 860-iscsi}
861 {return 861-owamp-control}
862 {return 862-twamp-control}
873 {return 873-rsync}
886 {return 886-iclcnet-locate}
887 {return 887-iclcnet_svinfo}
888 {return 888-accessbuilder}
900 {return 900-omginitialrefs}
901 {return 901-smpnameres}
902 {return 902-ideafarm-door}
903 {return 903-ideafarm-panic}
910 {return 910-kink}
911 {return 911-xact-backup}
912 {return 912-apex-mesh}
913 {return 913-apex-edge}
989 {return 989-ftps-data}
990 {return 990-ftps}
991 {return 991-nas}
992 {return 992-telnets}
993 {return 993-imaps}
994 {return 994-ircs}
995 {return 995-pop3s}
996 {return 996-vsinet}
997 {return 997-maitrd}
998 {return 998-busboy}
999 {return 999-puprouter}
1000 {return 1000-cadlock2}
1010 {return 1010-surf}
1021 {return 1021-exp1}
1022 {return 1022-exp2}
default {return $portnum2}
}}

if [string equal $protnum2 17] { 
switch $portnum2 {
0 {return 0-reservd}
1 {return 1-tcpmux}
2 {return 2-compressnet}
3 {return 3-compressnet}
5 {return 5-rje}
7 {return 7-echo}
9 {return 9-discard}
11 {return 11-systat}
13 {return 13-daytime}
17 {return 17-qotd}
18 {return 18-msp}
19 {return 19-chargen}
20 {return 20-ftp-data}
21 {return 21-ftp}
22 {return 22-ssh}
23 {return 23-telnet}
24 {return 24-privmail}
25 {return 25-smtp}
27 {return 27-nsw-fe}
29 {return 29-msg-icp}
31 {return 31-msg-auth}
33 {return 33-dsp}
35 {return 35-prvprtsvc}
37 {return 37-time}
38 {return 38-rap}
39 {return 39-rlp}
41 {return 41-graphics}
42 {return 42-name}
43 {return 43-nicname}
44 {return 44-mpm-flags}
45 {return 45-mpm}
46 {return 46-mpm-snd}
47 {return 47-ni-ftp}
48 {return 48-auditd}
49 {return 49-tacacs}
50 {return 50-re-mail-ck}
51 {return 51-la-maint}
52 {return 52-xns-time}
53 {return 53-domain}
54 {return 54-xns-ch}
55 {return 55-isi-gl}
56 {return 56-xns-auth}
57 {return 57-prvterm}
58 {return 58-xns-mail}
59 {return 59-prvtfiler}
61 {return 61-ni-mail}
62 {return 62-acas}
63 {return 63-whois++}
64 {return 64-covia}
65 {return 65-tacacs-ds}
66 {return 66-sql*net}
67 {return 67-bootps}
68 {return 68-bootpc}
69 {return 69-tftp}
70 {return 70-gopher}
71 {return 71-netrjs-1}
72 {return 72-netrjs-2}
73 {return 73-netrjs-3}
74 {return 74-netrjs-4}
75 {return 75-prvtdialer}
76 {return 76-deos}
77 {return 77-prvtRJE}
78 {return 78-vettcp}
79 {return 79-finger}
80 {return 80-http}
82 {return 82-xfer}
83 {return 83-mit-ml-dev}
84 {return 84-ctf}
85 {return 85-mit-ml-dev}
86 {return 86-mfcobol}
87 {return 87-prvtterm}
88 {return 88-kerberos}
89 {return 89-su-mit-tg}
90 {return 90-dnsix}
91 {return 91-mit-dov}
92 {return 92-npp}
93 {return 93-dcp}
94 {return 94-objcall}
95 {return 95-supdup}
96 {return 96-dixie}
97 {return 97-swift-rvf}
98 {return 98-tacnews}
99 {return 99-metagram}
101 {return 101-hostname}
102 {return 102-iso-tsap}
103 {return 103-gppitnp}
104 {return 104-acr-nema}
105 {return 105-cso}
106 {return 106-3com-tsmux}
107 {return 107-rtelnet}
108 {return 108-snagas}
109 {return 109-pop2}
110 {return 110-pop3}
111 {return 111-sunrpc}
112 {return 112-mcidas}
113 {return 113-auth}
115 {return 115-sftp}
116 {return 116-ansanotify}
117 {return 117-uucp-path}
118 {return 118-sqlserv}
119 {return 119-nntp}
120 {return 120-cfdptkt}
121 {return 121-erpc}
122 {return 122-smakynet}
123 {return 123-ntp}
124 {return 124-ansatrader}
125 {return 125-locus-map}
126 {return 126-nxedit}
127 {return 127-locus-con}
128 {return 128-gss-xlicen}
129 {return 129-pwdgen}
130 {return 130-cisco-fna}
131 {return 131-cisco-tna}
132 {return 132-cisco-sys}
133 {return 133-statsrv}
134 {return 134-ingres-net}
135 {return 135-epmap}
136 {return 136-profile}
137 {return 137-netbios-ns}
138 {return 138-netbios-dgm}
139 {return 139-netbios-ssn}
140 {return 140-emfis-data}
141 {return 141-emfis-cntl}
142 {return 142-bl-idm}
143 {return 143-imap}
144 {return 144-uma}
145 {return 145-uaac}
146 {return 146-iso-tp0}
147 {return 147-iso-ip}
148 {return 148-jargon}
149 {return 149-aed-512}
150 {return 150-sql-net}
151 {return 151-hems}
152 {return 152-bftp}
153 {return 153-sgmp}
154 {return 154-netsc-prod}
155 {return 155-netsc-dev}
156 {return 156-sqlsrv}
157 {return 157-knet-cmp}
158 {return 158-pcmail-srv}
159 {return 159-nss-routing}
160 {return 160-sgmp-traps}
161 {return 161-snmp}
162 {return 162-snmptrap}
163 {return 163-cmip-man}
164 {return 164-cmip-agent}
165 {return 165-xns-courier}
166 {return 166-s-net}
167 {return 167-namp}
168 {return 168-rsvd}
169 {return 169-send}
170 {return 170-print-srv}
171 {return 171-multiplex}
172 {return 172-cl/1}
173 {return 173-xyplex-mux}
174 {return 174-mailq}
175 {return 175-vmnet}
176 {return 176-genrad-mux}
177 {return 177-xdmcp}
178 {return 178-nextstep}
179 {return 179-bgp}
180 {return 180-ris}
181 {return 181-unify}
182 {return 182-audit}
183 {return 183-ocbinder}
184 {return 184-ocserver}
185 {return 185-remote-kis}
186 {return 186-kis}
187 {return 187-aci}
188 {return 188-mumps}
189 {return 189-qft}
190 {return 190-gacp}
191 {return 191-prospero}
192 {return 192-osu-nms}
193 {return 193-srmp}
194 {return 194-irc}
195 {return 195-dn6-nlm-aud}
196 {return 196-dn6-smm-red}
197 {return 197-dls}
198 {return 198-dls-mon}
199 {return 199-smux}
200 {return 200-src}
201 {return 201-at-rtmp}
202 {return 202-at-nbp}
203 {return 203-at-3}
204 {return 204-at-echo}
205 {return 205-at-5}
206 {return 206-at-zis}
207 {return 207-at-7}
208 {return 208-at-8}
209 {return 209-qmtp}
210 {return 210-z39.50}
211 {return 211-914c/g}
212 {return 212-anet}
213 {return 213-ipx}
214 {return 214-vmpwscs}
215 {return 215-softpc}
216 {return 216-CAIlic}
217 {return 217-dbase}
218 {return 218-mpp}
219 {return 219-uarps}
220 {return 220-imap3}
221 {return 221-fln-spx}
222 {return 222-rsh-spx}
223 {return 223-cdc}
224 {return 224-masqdialer}
242 {return 242-direct}
243 {return 243-sur-meas}
244 {return 244-inbusiness}
245 {return 245-link}
246 {return 246-dsp3270}
247 {return 247-subntbcst_tftp}
248 {return 248-bhfhs}
256 {return 256-rap}
257 {return 257-set}
259 {return 259-esro-gen}
260 {return 260-openport}
261 {return 261-nsiiops}
262 {return 262-arcisdms}
263 {return 263-hdap}
264 {return 264-bgmp}
265 {return 265-x-bone-ctl}
266 {return 266-sst}
267 {return 267-td-service}
268 {return 268-td-replica}
269 {return 269-manet}
270 {return 270-gist}
280 {return 280-http-mgmt}
281 {return 281-personal-link}
282 {return 282-cableport-ax}
283 {return 283-rescap}
284 {return 284-corerjd}
286 {return 286-fxp}
287 {return 287-k-block}
308 {return 308-novastorbakcup}
309 {return 309-entrusttime}
310 {return 310-bhmds}
311 {return 311-asip-webadmin}
312 {return 312-vslmp}
313 {return 313-magenta-logic}
314 {return 314-opalis-robot}
315 {return 315-dpsi}
316 {return 316-decauth}
317 {return 317-zannet}
318 {return 318-pkix-timestamp}
319 {return 319-ptp-event}
320 {return 320-ptp-general}
321 {return 321-pip}
322 {return 322-rtsps}
333 {return 333-texar}
344 {return 344-pdap}
345 {return 345-pawserv}
346 {return 346-zserv}
347 {return 347-fatserv}
348 {return 348-csi-sgwp}
349 {return 349-mftp}
350 {return 350-matip-type-a}
351 {return 351-matip-type-b}
352 {return 352-dtag-ste-sb}
353 {return 353-ndsauth}
354 {return 354-bh611}
355 {return 355-datex-asn}
356 {return 356-cloanto-net-1}
357 {return 357-bhevent}
358 {return 358-shrinkwrap}
359 {return 359-nsrmp}
360 {return 360-scoi2odialog}
361 {return 361-semantix}
362 {return 362-srssend}
363 {return 363-rsvp_tunnel}
364 {return 364-aurora-cmgr}
365 {return 365-dtk}
366 {return 366-odmr}
367 {return 367-mortgageware}
368 {return 368-qbikgdp}
369 {return 369-rpc2portmap}
370 {return 370-codaauth2}
371 {return 371-clearcase}
372 {return 372-ulistproc}
373 {return 373-legent-1}
374 {return 374-legent-2}
375 {return 375-hassle}
376 {return 376-nip}
377 {return 377-tnETOS}
378 {return 378-dsETOS}
379 {return 379-is99c}
380 {return 380-is99s}
381 {return 381-hp-collector}
382 {return 382-hp-managed-node}
383 {return 383-hp-alarm-mgr}
384 {return 384-arns}
385 {return 385-ibm-app}
386 {return 386-asa}
387 {return 387-aurp}
388 {return 388-unidata-ldm}
389 {return 389-ldap}
390 {return 390-uis}
391 {return 391-synotics-relay}
392 {return 392-synotics-broker}
393 {return 393-meta5}
394 {return 394-embl-ndt}
395 {return 395-netcp}
396 {return 396-netware-ip}
397 {return 397-mptn}
398 {return 398-kryptolan}
399 {return 399-iso-tsap-c2}
400 {return 400-osb-sd}
401 {return 401-ups}
402 {return 402-genie}
403 {return 403-decap}
404 {return 404-nced}
405 {return 405-ncld}
406 {return 406-imsp}
407 {return 407-timbuktu}
408 {return 408-prm-sm}
409 {return 409-prm-nm}
410 {return 410-decladebug}
411 {return 411-rmt}
412 {return 412-synoptics-trap}
413 {return 413-smsp}
414 {return 414-infoseek}
415 {return 415-bnet}
416 {return 416-silverplatter}
417 {return 417-onmux}
418 {return 418-hyper-g}
419 {return 419-ariel1}
420 {return 420-smpte}
421 {return 421-ariel2}
422 {return 422-ariel3}
423 {return 423-opc-job-start}
424 {return 424-opc-job-track}
425 {return 425-icad-el}
426 {return 426-smartsdp}
427 {return 427-svrloc}
428 {return 428-ocs_cmu}
429 {return 429-ocs_amu}
430 {return 430-utmpsd}
431 {return 431-utmpcd}
432 {return 432-iasd}
433 {return 433-nnsp}
434 {return 434-mobileip-agent}
435 {return 435-mobilip-mn}
436 {return 436-dna-cml}
437 {return 437-comscm}
438 {return 438-dsfgw}
439 {return 439-dasp}
440 {return 440-sgcp}
441 {return 441-decvms-sysmgt}
442 {return 442-cvc_hostd}
443 {return 443-https}
444 {return 444-snpp}
445 {return 445-microsoft-ds}
446 {return 446-ddm-rdb}
447 {return 447-ddm-dfm}
448 {return 448-ddm-ssl}
449 {return 449-as-servermap}
450 {return 450-tserver}
451 {return 451-sfs-smp-net}
452 {return 452-sfs-config}
453 {return 453-creativeserver}
454 {return 454-contentserver}
455 {return 455-creativepartnr}
456 {return 456-macon-udp}
457 {return 457-scohelp}
458 {return 458-appleqtc}
459 {return 459-ampr-rcmd}
460 {return 460-skronk}
461 {return 461-datasurfsrv}
462 {return 462-datasurfsrvsec}
463 {return 463-alpes}
464 {return 464-kpasswd}
465 {return 465-igmpv3lite}
466 {return 466-digital-vrc}
467 {return 467-mylex-mapd}
468 {return 468-photuris}
469 {return 469-rcp}
470 {return 470-scx-proxy}
471 {return 471-mondex}
472 {return 472-ljk-login}
473 {return 473-hybrid-pop}
474 {return 474-tn-tl-w2}
475 {return 475-tcpnethaspsrv}
476 {return 476-tn-tl-fd1}
477 {return 477-ss7ns}
478 {return 478-spsc}
479 {return 479-iafserver}
480 {return 480-iafdbase}
481 {return 481-ph}
482 {return 482-bgs-nsi}
483 {return 483-ulpnet}
484 {return 484-integra-sme}
485 {return 485-powerburst}
486 {return 486-avian}
487 {return 487-saft}
488 {return 488-gss-http}
489 {return 489-nest-protocol}
490 {return 490-micom-pfs}
491 {return 491-go-login}
492 {return 492-ticf-1}
493 {return 493-ticf-2}
494 {return 494-pov-ray}
495 {return 495-intecourier}
496 {return 496-pim-rp-disc}
497 {return 497-dantz}
498 {return 498-siam}
499 {return 499-iso-ill}
500 {return 500-isakmp}
501 {return 501-stmf}
502 {return 502-asa-appl-proto}
503 {return 503-intrinsa}
504 {return 504-citadel}
505 {return 505-mailbox-lm}
506 {return 506-ohimsrv}
507 {return 507-crs}
508 {return 508-xvttp}
509 {return 509-snare}
510 {return 510-fcp}
511 {return 511-passgo}
512 {return 512-comsat}
513 {return 513-who}
514 {return 514-syslog}
515 {return 515-printer}
516 {return 516-videotex}
517 {return 517-talk}
518 {return 518-ntalk}
519 {return 519-utime}
520 {return 520-router}
521 {return 521-ripng}
522 {return 522-ulp}
523 {return 523-ibm-db2}
524 {return 524-ncp}
525 {return 525-timed}
526 {return 526-tempo}
527 {return 527-stx}
528 {return 528-custix}
529 {return 529-irc-serv}
530 {return 530-courier}
531 {return 531-conference}
532 {return 532-netnews}
533 {return 533-netwall}
534 {return 534-windream}
535 {return 535-iiop}
536 {return 536-opalis-rdv}
537 {return 537-nmsp}
538 {return 538-gdomap}
539 {return 539-apertus-ldp}
540 {return 540-uucp}
541 {return 541-uucp-rlogin}
542 {return 542-commerce}
543 {return 543-klogin}
544 {return 544-kshell}
545 {return 545-appleqtcsrvr}
546 {return 546-dhcpv6-client}
547 {return 547-dhcpv6-server}
548 {return 548-afpovertcp}
549 {return 549-idfp}
550 {return 550-new-rwho}
551 {return 551-cybercash}
552 {return 552-devshr-nts}
553 {return 553-pirp}
554 {return 554-rtsp}
555 {return 555-dsf}
556 {return 556-remotefs}
557 {return 557-openvms-sysipc}
558 {return 558-sdnskmp}
559 {return 559-teedtap}
560 {return 560-rmonitor}
561 {return 561-monitor}
562 {return 562-chshell}
563 {return 563-nntps}
564 {return 564-9pfs}
565 {return 565-whoami}
566 {return 566-streettalk}
567 {return 567-banyan-rpc}
568 {return 568-ms-shuttle}
569 {return 569-ms-rome}
570 {return 570-meter}
571 {return 571-meter}
572 {return 572-sonar}
573 {return 573-banyan-vip}
574 {return 574-ftp-agent}
575 {return 575-vemmi}
576 {return 576-ipcd}
577 {return 577-vnas}
578 {return 578-ipdd}
579 {return 579-decbsrv}
580 {return 580-sntp-heartbeat}
581 {return 581-bdp}
582 {return 582-scc-security}
583 {return 583-philips-vc}
584 {return 584-keyserver}
586 {return 586-password-chg}
587 {return 587-submission}
588 {return 588-cal}
589 {return 589-eyelink}
590 {return 590-tns-cml}
591 {return 591-http-alt}
592 {return 592-eudora-set}
593 {return 593-http-rpc-epmap}
594 {return 594-tpip}
595 {return 595-cab-protocol}
596 {return 596-smsd}
597 {return 597-ptcnameservice}
598 {return 598-sco-websrvrmg3}
599 {return 599-acp}
600 {return 600-ipcserver}
601 {return 601-syslog-conn}
602 {return 602-xmlrpc-beep}
603 {return 603-idxp}
604 {return 604-tunnel}
605 {return 605-soap-beep}
606 {return 606-urm}
607 {return 607-nqs}
608 {return 608-sift-uft}
609 {return 609-npmp-trap}
610 {return 610-npmp-local}
611 {return 611-npmp-gui}
612 {return 612-hmmp-ind}
613 {return 613-hmmp-op}
614 {return 614-sshell}
615 {return 615-sco-inetmgr}
616 {return 616-sco-sysmgr}
617 {return 617-sco-dtmgr}
618 {return 618-dei-icda}
619 {return 619-compaq-evm}
620 {return 620-sco-websrvrmgr}
621 {return 621-escp-ip}
622 {return 622-collaborator}
623 {return 623-asf-rmcp}
624 {return 624-cryptoadmin}
625 {return 625-dec_dlm}
626 {return 626-asia}
627 {return 627-passgo-tivoli}
628 {return 628-qmqp}
629 {return 629-3com-amp3}
630 {return 630-rda}
631 {return 631-ipp}
632 {return 632-bmpp}
633 {return 633-servstat}
634 {return 634-ginad}
635 {return 635-rlzdbase}
636 {return 636-ldaps}
637 {return 637-lanserver}
638 {return 638-mcns-sec}
639 {return 639-msdp}
640 {return 640-entrust-sps}
641 {return 641-repcmd}
642 {return 642-esro-emsdp}
643 {return 643-sanity}
644 {return 644-dwr}
645 {return 645-pssc}
646 {return 646-ldp}
647 {return 647-dhcp-failover}
648 {return 648-rrp}
649 {return 649-cadview-3d}
650 {return 650-obex}
651 {return 651-ieee-mms}
652 {return 652-hello-port}
653 {return 653-repscmd}
654 {return 654-aodv}
655 {return 655-tinc}
656 {return 656-spmp}
657 {return 657-rmc}
658 {return 658-tenfold}
660 {return 660-mac-srvr-admin}
661 {return 661-hap}
662 {return 662-pftp}
663 {return 663-purenoise}
664 {return 664-asf-secure-rmcp}
665 {return 665-sun-dr}
666 {return 666-mdqs}
667 {return 667-disclose}
668 {return 668-mecomm}
669 {return 669-meregister}
670 {return 670-vacdsm-sws}
671 {return 671-vacdsm-app}
672 {return 672-vpps-qua}
673 {return 673-cimplex}
674 {return 674-acap}
675 {return 675-dctp}
676 {return 676-vpps-via}
677 {return 677-vpp}
678 {return 678-ggf-ncp}
679 {return 679-mrm}
680 {return 680-entrust-aaas}
681 {return 681-entrust-aams}
682 {return 682-xfr}
683 {return 683-corba-iiop}
684 {return 684-corba-iiop-ssl}
685 {return 685-mdc-portmapper}
686 {return 686-hcp-wismar}
687 {return 687-asipregistry}
688 {return 688-realm-rusd}
689 {return 689-nmap}
690 {return 690-vatp}
691 {return 691-msexch-routing}
692 {return 692-hyperwave-isp}
693 {return 693-connendp}
694 {return 694-ha-cluster}
695 {return 695-ieee-mms-ssl}
696 {return 696-rushd}
697 {return 697-uuidgen}
698 {return 698-olsr}
699 {return 699-accessnetwork}
700 {return 700-epp}
701 {return 701-lmp}
702 {return 702-iris-beep}
704 {return 704-elcsd}
705 {return 705-agentx}
706 {return 706-silc}
707 {return 707-borland-dsj}
709 {return 709-entrust-kmsh}
710 {return 710-entrust-ash}
711 {return 711-cisco-tdp}
712 {return 712-tbrpf}
713 {return 713-iris-xpc}
714 {return 714-iris-xpcs}
715 {return 715-iris-lwz}
716 {return 716-pana}
729 {return 729-netviewdm1}
730 {return 730-netviewdm2}
731 {return 731-netviewdm3}
741 {return 741-netgw}
742 {return 742-netrcs}
744 {return 744-flexlm}
747 {return 747-fujitsu-dev}
748 {return 748-ris-cm}
749 {return 749-kerberos-adm}
750 {return 750-loadav}
751 {return 751-pump}
752 {return 752-qrh}
753 {return 753-rrh}
754 {return 754-tell}
758 {return 758-nlogin}
759 {return 759-con}
760 {return 760-ns}
761 {return 761-rxe}
762 {return 762-quotad}
763 {return 763-cycleserv}
764 {return 764-omserv}
765 {return 765-webster}
767 {return 767-phonebook}
769 {return 769-vid}
770 {return 770-cadlock}
771 {return 771-rtip}
772 {return 772-cycleserv2}
773 {return 773-notify}
774 {return 774-acmaint_dbd}
775 {return 775-acmaint_transd}
776 {return 776-wpages}
777 {return 777-multiling-http}
780 {return 780-wpgs}
800 {return 800-mdbs_daemon}
801 {return 801-device}
810 {return 810-fcp-udp}
828 {return 828-itm-mcell-s}
829 {return 829-pkix-3-ca-ra}
830 {return 830-netconf-ssh}
831 {return 831-netconf-beep}
832 {return 832-netconfsoaphttp}
833 {return 833-netconfsoapbeep}
847 {return 847-dhcp-failover2}
848 {return 848-gdoi}
860 {return 860-iscsi}
861 {return 861-owamp-control}
862 {return 862-twamp-control}
873 {return 873-rsync}
886 {return 886-iclcnet-locate}
887 {return 887-iclcnet_svinfo}
888 {return 888-accessbuilder}
900 {return 900-omginitialrefs}
901 {return 901-smpnameres}
902 {return 902-ideafarm-door}
903 {return 903-ideafarm-panic}
910 {return 910-kink}
911 {return 911-xact-backup}
912 {return 912-apex-mesh}
913 {return 913-apex-edge}
989 {return 989-ftps-data}
990 {return 990-ftps}
991 {return 991-nas}
992 {return 992-telnets}
993 {return 993-imaps}
994 {return 994-ircs}
995 {return 995-pop3s}
996 {return 996-vsinet}
997 {return 997-maitrd}
998 {return 998-puparp}
999 {return 999-applix}
1000 {return 1000-cadlock2}
1010 {return 1010-surf}
1021 {return 1021-exp1}
1022 {return 1022-exp2}
default {return $portnum2}
}}

}
#######
proc CnvrtProtNum {protnum2} {
if {[string equal $protnum2 6]} {return TCP} else {
  if {[string equal $protnum2 17]} {return UDP} else {
  
switch $protnum2 {
0 {return HOPOPT}
1 {return ICMP}
2 {return IGMP}
3 {return GGP}
4 {return IPv4}
5 {return ST}
7 {return CBT}
8 {return EGP}
9 {return IGP}
10 {return BBN-RCC-MON}
11 {return NVP-II}
12 {return PUP}
13 {return ARGUS}
14 {return EMCON}
15 {return XNET}
16 {return CHAOS}
18 {return MUX}
19 {return DCN-MEAS}
20 {return HMP}
21 {return PRM}
22 {return XNS-IDP}
23 {return TRUNK-1}
24 {return TRUNK-2}
25 {return LEAF-1}
26 {return LEAF-2}
27 {return RDP}
28 {return IRTP}
29 {return ISO-TP4}
30 {return NETBLT}
31 {return MFE-NSP}
32 {return MERIT-INP}
33 {return DCCP}
34 {return 3PC}
35 {return IDPR}
36 {return XTP}
37 {return DDP}
38 {return IDPR-CMTP}
39 {return TP++}
40 {return IL}
41 {return IPv6}
42 {return SDRP}
43 {return IPv6-Route}
44 {return IPv6-Frag}
45 {return IDRP}
46 {return RSVP}
47 {return GRE}
48 {return DSR}
49 {return BNA}
50 {return ESP}
51 {return AH}
52 {return I-NLSP}
53 {return SWIPE}
54 {return NARP}
55 {return MOBILE}
56 {return TLSP}
57 {return SKIP}
58 {return IPv6-ICMP}
59 {return IPv6-NoNxt}
60 {return IPv6-Opts}
61 {return any}
62 {return CFTP}
63 {return any}
64 {return SAT-EXPAK}
65 {return KRYPTOLAN}
66 {return RVD}
67 {return IPPC}
68 {return any}
69 {return SAT-MON}
70 {return VISA}
71 {return IPCV}
72 {return CPNX}
73 {return CPHB}
74 {return WSN}
75 {return PVP}
76 {return BR-SAT-MON}
77 {return SUN-ND}
78 {return WB-MON}
79 {return WB-EXPAK}
80 {return ISO-IP}
81 {return VMTP}
82 {return SECURE-VMTP}
83 {return VINES}
84 {return TTP}
85 {return NSFNET-IGP}
86 {return DGP}
87 {return TCF}
88 {return EIGRP}
89 {return OSPF}
90 {return Sprite-RPC}
91 {return LARP}
92 {return MTP}
93 {return AX.25}
94 {return IPIP}
95 {return MICP}
96 {return SCC-SP}
97 {return ETHERIP}
98 {return ENCAP}
99 {return any}
100 {return GMTP}
101 {return IFMP}
102 {return PNNI}
103 {return PIM}
104 {return ARIS}
105 {return SCPS}
106 {return QNX}
107 {return A/N}
108 {return IPComp}
109 {return SNP}
110 {return Compaq-Peer}
111 {return IPX-in-IP}
112 {return VRRP}
113 {return PGM}
114 {return any}
115 {return L2TP}
116 {return DDX}
117 {return IATP}
118 {return STP}
119 {return SRP}
120 {return UTI}
121 {return SMP}
122 {return SM}
123 {return PTP}
124 {return ISIS}
125 {return FIRE}
126 {return CRTP}
127 {return CRUDP}
128 {return SSCOPMCE}
129 {return IPLT}
130 {return SPS}
131 {return PIPE}
132 {return SCTP}
133 {return FC}
134 {return RSVP-E2E-IGNORE}
135 {return Mobility}
136 {return UDPLite}
137 {return MPLS-in-IP}
138 {return manet}
139 {return HIP}
140 {return Shim6}
141 {return WESP}
142 {return ROHC}
default {return $protnum2} }  }}
}
#######
proc ModifyTimeStamp1 {tstamp2} {
regsub -all {:} [string range $tstamp2 0 4] "" newString; return $newString
}
#######
proc ModifyTimeStamp2 {tstamp2} {
return "[string range $tstamp2 0 1]:[string range $tstamp2 2 3]"
}
#######
proc printReportHeader {} {
       set lf2 "%-16s %-15s %-13s %-6s %-4s %-5s %9s %7s"
       puts  "\n";
       puts  [format $lf2 \ SRCIP DSTIP APPLICATION PROT DIRN Start AvgBit/s AvgPkt/s]
       puts "==================================================================================="
}
######
proc BitCnvrt { num } {
     if {$num < 1} {return [expr round([expr $num * 1000])]} else {
       if {$num < 1e3} {return "[expr round([lindex $num 0])]K"} else {
         if {$num < 1e6} {regsub {\.[0-9]*} $num "" num; while {[regsub {^(\d+)(\d\d\d)} $num "\\1 \\2" num]} {}; return "[format %1.2f [lindex $num 0].[lindex $num 1]]M" } else {
           if {$num < 1e9} {regsub {\.[0-9]*} $num "" num; while {[regsub {^(\d+)(\d\d\d)} $num "\\1 \\2" num]} {}; return "[string range [lindex $num 0].[lindex $num 1] 0 4]G"} else {
               regsub {\.[0-9]*} $num "" num; while {[regsub {^(\d+)(\d\d\d)} $num "\\1 \\2" num]} {}; return "[string range [lindex $num 0].[lindex $num 1] 0 4]T"} }}}
}
######
proc RealTimeTraffic {refresh2 flowMonName2} {

for {set j 0} {$j <= 4} {incr j} {

   set numlines 0

   if [catch {cli_open} result] {puts "Error: $result"} else {array set cli $result}
   if [catch {cli_exec $cli(fd) "enable"} result] {puts "Error: $result"}
   if [catch {cli_exec $cli(fd) "show flow monitor $flowMonName2 cache sort highest counter bytes top 400 format table | in Input|Output"} result] { puts "Error: $result"} else { set cmdResult $result}
   if [catch {cli_close $cli(fd) $cli(tty_id)} result] {puts "Error: $result"}
   foreach line [split $cmdResult "\n" ] {
     if {[string length $line]>0} {lappend FlowTable [list [lindex $line 0] [lindex $line 1] [lindex $line 2] [lindex $line 3] [lindex $line 5] [lindex $line 7] [lindex $line 8] [lindex $line 9] [ModifyTimeStamp1 [lindex $line 10]] ] }  
					 }
                                         
 # DATA STORAGE into Arrays: bytesArr, startTimeOffset, endTimeOffset
 # Record bytes for each flow
 foreach searchlines $FlowTable {
    # only process valid lines
    if {[string match *\[0-9\]*\.*\[0-9\]*\.*\[0-9\]* $searchlines]} {
      # determine well known port, otherwise use port1/port2 notation
      if {[lindex $searchlines 2]<= 1024 && [lindex $searchlines 2]>=1} {set c1 [lindex $searchlines 2]} else { 
         if {[lindex $searchlines 3]<= 1024 && [lindex $searchlines 3]>=1} {set c1 [lindex $searchlines 3]} else {
            set c1 [lindex $searchlines 2]/[lindex $searchlines 3]}                                        
                                                                                                              } 
      # insert each flow into array using 5-tuple array index
      set a1 [lindex $searchlines 0]; set b1 [lindex $searchlines 1]; set prot [lindex $searchlines 4]; set d1 [lindex $searchlines 5]; set e1 [lindex $searchlines 6]; set st  [lindex $searchlines 8]
      set startBytes($a1,$b1,$c1,$prot,$d1,$st) $e1
          
      # endTimeOffset is updated each time a flow is seen
      set startPacketCnt($a1,$b1,$c1,$prot,$d1,$st) [lindex $searchlines 7]
   }
 }

  if {[catch {[callwait $refresh2]} err5]} {}
    

##############################

   set lf2 "%-16s %-15s %-13s %-6s %-4s %-5s %7s %6s"
   set FlowTable [list]

   
   if [catch {cli_open} result] {puts "Error: $result"} else {array set cli $result}
   if [catch {cli_exec $cli(fd) "enable"} result] {puts "Error: $result"}
   if [catch {cli_exec $cli(fd) "show flow monitor $flowMonName2 cache sort highest counter bytes top 400 format table | in Input|Output"} result] { puts "Error: $result"} else { set cmdResult $result}
   if [catch {cli_close $cli(fd) $cli(tty_id)} result] {puts "Error: $result"}
  
   foreach line [split $cmdResult "\n" ] {
     if {[string length $line]>0} {lappend FlowTable [list [lindex $line 0] [lindex $line 1] [lindex $line 2] [lindex $line 3] [lindex $line 5] [lindex $line 7] [lindex $line 8] [lindex $line 9] [ModifyTimeStamp1 [lindex $line 10]] ] }  
					 }
                                         
 # DATA STORAGE into Arrays: bytesArr, startTimeOffset, endTimeOffset
 # Record bytes for each flow

 foreach searchlines $FlowTable {
    # only process valid lines
    if {[string match *\[0-9\]*\.*\[0-9\]*\.*\[0-9\]* $searchlines]} {
       # determine well known port, otherwise use port1/port2 notation
       if {[lindex $searchlines 2]<= 1024 && [lindex $searchlines 2]>=1} {set c1 [lindex $searchlines 2]} else { 
         if {[lindex $searchlines 3]<= 1024 && [lindex $searchlines 3]>=1} {set c1 [lindex $searchlines 3]} else {set c1 [lindex $searchlines 2]/[lindex $searchlines 3]}                                        
                                                                                                              } 
       # insert each flow into array using 5-tuple array index, sum bytes during each insert
       set a1 [lindex $searchlines 0]; set b1 [lindex $searchlines 1]; set prot [lindex $searchlines 4]; set d1 [lindex $searchlines 5]; set e1 [lindex $searchlines 6]; set st [lindex $searchlines 8]
          
       if {![info exists startBytes($a1,$b1,$c1,$prot,$d1,$st)]} {set startBytes($a1,$b1,$c1,$prot,$d1,$st) 0}
       if {![info exists startPacketCnt($a1,$b1,$c1,$prot,$d1,$st)]} {set startPacketCnt($a1,$b1,$c1,$prot,$d1,$st) 0}
       set endBytes($a1,$b1,$c1,$prot,$d1,$st) $e1
       set endPacketCnt($a1,$b1,$c1,$prot,$d1,$st) [lindex $searchlines 7]

       set deltaBytes($a1,$b1,$c1,$prot,$d1,$st) [format %1.3f [expr [set endBytes($a1,$b1,$c1,$prot,$d1,$st)] - [set startBytes($a1,$b1,$c1,$prot,$d1,$st)]]]
       set deltaPacketCnt($a1,$b1,$c1,$prot,$d1,$st) [expr [set endPacketCnt($a1,$b1,$c1,$prot,$d1,$st)] - [set startPacketCnt($a1,$b1,$c1,$prot,$d1,$st)]]
       #puts "startPktCnt=[set startPacketCnt($a1,$b1,$c1,$prot,$d1,$st)]"	
       #puts "endPktCnt=[set endPacketCnt($a1,$b1,$c1,$prot,$d1,$st)]"	
       #puts "endBytes=[set endBytes($a1,$b1,$c1,$prot,$d1,$st)]"	
       #puts "startBytes=[set startBytes($a1,$b1,$c1,$prot,$d1,$st)]"	


    }
 }


      foreach {key value} [array get deltaBytes]  {lappend byteslist [list $key $value]}
      printReportHeader
      foreach entry [lsort -real -index 1 -decreasing $byteslist] {
        if {$numlines>=20} {break}
        regsub -all {\,} $entry " " myentry
        if {0 < [set deltaPacketCnt([lindex $myentry 0],[lindex $myentry 1],[lindex $myentry 2],[lindex $myentry 3],[lindex $myentry 4],[lindex $myentry 5])]} {
           set pktPerSec [expr [set deltaPacketCnt([lindex $myentry 0],[lindex $myentry 1],[lindex $myentry 2],[lindex $myentry 3],[lindex $myentry 4],[lindex $myentry 5])] / $refresh2] 
        } else {set pktPerSec [set deltaPacketCnt([lindex $myentry 0],[lindex $myentry 1],[lindex $myentry 2],[lindex $myentry 3],[lindex $myentry 4],[lindex $myentry 5]) - ]} 
        if {[lindex $myentry 6] > 0} {puts [format $lf2 \ [lindex $myentry 0] [lindex $myentry 1] [string range [CnvrtPortNum [lindex $myentry 2] [lindex $myentry 3]] 0 12] [string range [CnvrtProtNum [lindex $myentry 3]] 0 5] [Dirn [lindex $myentry 4]] [ModifyTimeStamp2 [lindex $myentry 5]] [BitCnvrt [expr [expr 8*[lindex $myentry 6]] / [expr $refresh2 * 1000]]] $pktPerSec]}
        incr numlines
      }
  # zero out all arrays, lists
  set FlowTable [list]; set byteslist [list]; array unset endBytes; array unset startPacketCnt
  array unset deltaBytes; array unset startBytes; array unset deltaPacketCnt; array unset endPacketCnt
  

 }
}

## Main
##


if [catch {cli_open} result] {puts "Error: $result"} else {array set cli $result}
if [catch {cli_exec $cli(fd) "enable"} result] {puts "Error: $result"}

if [catch {cli_exec $cli(fd) "show run flow monitor | in flow monitor"} result] { puts "Error: $result"} else { set flowMonName [lindex $result 2]}
if [catch {cli_close $cli(fd) $cli(tty_id)} result] {puts "Error: $result"}


set refreshRate 7; set errFlag 0


# check arguments
array set arr_einfo [event_reqinfo]

set arglen [llength $argv]
if {$arr_einfo(argc) != 0} {
  set index 1
  while {$index <= $arr_einfo(argc)} {
    set arg $arr_einfo(arg$index)
    switch -exact -- $arg {
      {-f} {set args($arg) $arr_einfo(arg[incr index])}
      {-r} {set args($arg) $arr_einfo(arg[incr index])}
      default  {printHelp; set errFlag 1}
    }
    incr index
  }


  if {[info exists args(-f)]} {
    if {$args(-f) != ""} { set flowMonName $args(-f) }      	
  }

  if {[info exists args(-r)]} {
    if {$args(-r) != ""} {
       if {($args(-r) <= 30) && ($args(-r) >= 1)} {set refreshRate $args(-r)} else {printHelp; set errFlag 1}
    }
  }
}


if {!$errFlag} {
  puts -nonewline "Standby..."; flush stdout
  if {[catch {RealTimeTraffic $refreshRate $flowMonName} result]} {puts "Error: $result"}
}

