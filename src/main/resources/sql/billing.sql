PGDMP     $    4                {            billing    15.2    15.1 :    =           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            >           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            ?           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            @           1262    65536    billing    DATABASE     {   CREATE DATABASE billing WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';
    DROP DATABASE billing;
                postgres    false            �            1255    65658    call_trigger_func()    FUNCTION     Z  CREATE FUNCTION public.call_trigger_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare seconds int;
    call_minutes int;
    minutes_balance_value int;
    spent_minutes int;
begin
    new.duration := end_timestamp - start_timestamp;

    seconds := extract(second from new.duration);

    call_minutes := (extract(day from duration) * 24 + extract(hour from duration)) * 60
                               + extract(minutes from duration);

    if seconds != 0 then
        call_minutes := call_minutes + 1;
    end if;

    if new.call_type = '01' then
        if (select minutes_balance_in from tariff
            join phone p3 on tariff.tariff_id = p3.tariff_id
            where p3.user_phone = new.user_phone) = 0 then
            minutes_balance_value = (select minutes_balance
                                     from phone
                                     where user_phone = new.user_phone);
        else
            minutes_balance_value = 0;
        end if;
    else
        if (select minutes_balance_out from tariff
            join phone p3 on tariff.tariff_id = p3.tariff_id
            where p3.user_phone = new.user_phone) = 0 then
            minutes_balance_value = (select minutes_balance
                                     from phone
                                     where user_phone = new.user_phone);
        else
            minutes_balance_value = 0;
        end if;
    end if;

    if minutes_balance_value > call_minutes then
        spent_minutes = call_minutes;
    else
        spent_minutes = minutes_balance_value;
    end if;

    update phone p
    set minutes_balance = minutes_balance - spent_minutes
    where new.user_phone = p.user_phone;

    if new.call_type = '01' then
        new.cost = spent_minutes * (select minute_price_out from tariff
                                    join phone p2 on tariff.tariff_id = p2.tariff_id
                                    where p2.user_phone = new.user_phone)
                    + (call_minutes - spent_minutes) * (select expired_minute_price_out from tariff
                                                        join phone p2 on tariff.tariff_id = p2.tariff_id
                                                        where p2.user_phone = new.user_phone);
    else
        new.cost = spent_minutes * (select minute_price_in from tariff
                                    join phone p2 on tariff.tariff_id = p2.tariff_id
                                    where p2.user_phone = new.user_phone)
                    + (call_minutes - spent_minutes) * (select expired_minute_price_in from tariff
                                                        join phone p2 on tariff.tariff_id = p2.tariff_id
                                                        where p2.user_phone = new.user_phone);
    end if;
    return new;
end
$$;
 *   DROP FUNCTION public.call_trigger_func();
       public          postgres    false            �            1255    65738    change_tariff_trigger_func()    FUNCTION     t  CREATE FUNCTION public.change_tariff_trigger_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    new.old_tariff_id = (select tariff_id
                         from phone
                         where user_phone = new.user_phone);
    update phone
    set tariff_id = new.new_tariff_id
    where user_phone = new.user_phone;
    return new;
end
$$;
 3   DROP FUNCTION public.change_tariff_trigger_func();
       public          postgres    false            �            1255    65588    insert_call_trigger_func()    FUNCTION     �   CREATE FUNCTION public.insert_call_trigger_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    update Call
    set duration = new.end_timestamp - new.start_timestamp
    where Call.call_id=new.call_id;
end;
$$;
 1   DROP FUNCTION public.insert_call_trigger_func();
       public          postgres    false            �            1255    65656    payment_trigger_func()    FUNCTION     �   CREATE FUNCTION public.payment_trigger_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    update phone
    set user_balance = user_balance + new.money
    where phone.user_phone = new.user_phone;
end
$$;
 -   DROP FUNCTION public.payment_trigger_func();
       public          postgres    false            �            1255    65660    phone_trigger_func()    FUNCTION       CREATE FUNCTION public.phone_trigger_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare minutes_balance_in_value int;
        minutes_balance_out_value int;
        minutes_balance_summary_value int;
        minutes int;
begin
    new.user_balance := 0;

    minutes_balance_in_value = (select minutes_balance_in from tariff where tariff_id = new.tariff_id);
    minutes_balance_out_value = (select minutes_balance_out from tariff where tariff_id = new.tariff_id);
    minutes_balance_summary_value = (select minutes_balance_summary from tariff where tariff_id = new.tariff_id);
    minutes = select_max_of_three(minutes_balance_in_value, minutes_balance_out_value, minutes_balance_summary_value);
    new.minutes_balance := minutes;
    return new;
end
$$;
 +   DROP FUNCTION public.phone_trigger_func();
       public          postgres    false            �            1255    65714 .   select_max_of_three(integer, integer, integer)    FUNCTION       CREATE FUNCTION public.select_max_of_three(a integer, b integer, c integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    if a >= b and a >= c then
        return a;
    end if;
    if b >= c then
        return b;
    else
        return c;
    end if;
END;
$$;
 K   DROP FUNCTION public.select_max_of_three(a integer, b integer, c integer);
       public          postgres    false            �            1259    65674    call    TABLE     �   CREATE TABLE public.call (
    call_id integer NOT NULL,
    call_type character(2),
    user_phone character(11),
    start_timestamp timestamp without time zone,
    end_timestamp timestamp without time zone,
    duration interval,
    cost real
);
    DROP TABLE public.call;
       public         heap    postgres    false            �            1259    65673    call_call_id_seq    SEQUENCE     �   CREATE SEQUENCE public.call_call_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.call_call_id_seq;
       public          postgres    false    219            A           0    0    call_call_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.call_call_id_seq OWNED BY public.call.call_id;
          public          postgres    false    218            �            1259    65717    change_tariff    TABLE     �   CREATE TABLE public.change_tariff (
    id integer NOT NULL,
    user_phone character(11),
    old_tariff_id character varying(3),
    new_tariff_id character varying(3)
);
 !   DROP TABLE public.change_tariff;
       public         heap    postgres    false            �            1259    65716    change_tariff_id_seq    SEQUENCE     �   CREATE SEQUENCE public.change_tariff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.change_tariff_id_seq;
       public          postgres    false    224            B           0    0    change_tariff_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.change_tariff_id_seq OWNED BY public.change_tariff.id;
          public          postgres    false    223            �            1259    65698 
   credential    TABLE     n   CREATE TABLE public.credential (
    user_phone character(11),
    user_password text,
    role_id integer
);
    DROP TABLE public.credential;
       public         heap    postgres    false            �            1259    65687    payment    TABLE     g   CREATE TABLE public.payment (
    id integer NOT NULL,
    user_phone character(11),
    money real
);
    DROP TABLE public.payment;
       public         heap    postgres    false            �            1259    65686    payment_id_seq    SEQUENCE     �   CREATE SEQUENCE public.payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.payment_id_seq;
       public          postgres    false    221            C           0    0    payment_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.payment_id_seq OWNED BY public.payment.id;
          public          postgres    false    220            �            1259    65662    phone    TABLE     �   CREATE TABLE public.phone (
    user_phone character(11) NOT NULL,
    full_name character varying(50),
    tariff_id character(2),
    user_balance real,
    minutes_balance integer
);
    DROP TABLE public.phone;
       public         heap    postgres    false            �            1259    65623    role    TABLE     `   CREATE TABLE public.role (
    role_id integer NOT NULL,
    role_name character varying(20)
);
    DROP TABLE public.role;
       public         heap    postgres    false            �            1259    65622    role_role_id_seq    SEQUENCE     �   CREATE SEQUENCE public.role_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.role_role_id_seq;
       public          postgres    false    216            D           0    0    role_role_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.role_role_id_seq OWNED BY public.role.role_id;
          public          postgres    false    215            �            1259    65537    tariff    TABLE     �  CREATE TABLE public.tariff (
    tariff_id character varying(3) NOT NULL,
    tariff_name character varying(20),
    period_price integer,
    minutes_balance_out integer,
    minutes_balance_in integer,
    minutes_balance_summary integer,
    minute_price_out real,
    minute_price_in real,
    expired_minute_price_out real,
    expired_minute_price_in real,
    currency character varying(10)
);
    DROP TABLE public.tariff;
       public         heap    postgres    false            �           2604    65677    call call_id    DEFAULT     l   ALTER TABLE ONLY public.call ALTER COLUMN call_id SET DEFAULT nextval('public.call_call_id_seq'::regclass);
 ;   ALTER TABLE public.call ALTER COLUMN call_id DROP DEFAULT;
       public          postgres    false    218    219    219            �           2604    65720    change_tariff id    DEFAULT     t   ALTER TABLE ONLY public.change_tariff ALTER COLUMN id SET DEFAULT nextval('public.change_tariff_id_seq'::regclass);
 ?   ALTER TABLE public.change_tariff ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    224    223    224            �           2604    65690 
   payment id    DEFAULT     h   ALTER TABLE ONLY public.payment ALTER COLUMN id SET DEFAULT nextval('public.payment_id_seq'::regclass);
 9   ALTER TABLE public.payment ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    220    221    221            �           2604    65626    role role_id    DEFAULT     l   ALTER TABLE ONLY public.role ALTER COLUMN role_id SET DEFAULT nextval('public.role_role_id_seq'::regclass);
 ;   ALTER TABLE public.role ALTER COLUMN role_id DROP DEFAULT;
       public          postgres    false    216    215    216            5          0    65674    call 
   TABLE DATA           n   COPY public.call (call_id, call_type, user_phone, start_timestamp, end_timestamp, duration, cost) FROM stdin;
    public          postgres    false    219   QU       :          0    65717    change_tariff 
   TABLE DATA           U   COPY public.change_tariff (id, user_phone, old_tariff_id, new_tariff_id) FROM stdin;
    public          postgres    false    224   nU       8          0    65698 
   credential 
   TABLE DATA           H   COPY public.credential (user_phone, user_password, role_id) FROM stdin;
    public          postgres    false    222   �U       7          0    65687    payment 
   TABLE DATA           8   COPY public.payment (id, user_phone, money) FROM stdin;
    public          postgres    false    221   �U       3          0    65662    phone 
   TABLE DATA           `   COPY public.phone (user_phone, full_name, tariff_id, user_balance, minutes_balance) FROM stdin;
    public          postgres    false    217   �U       2          0    65623    role 
   TABLE DATA           2   COPY public.role (role_id, role_name) FROM stdin;
    public          postgres    false    216   c�       0          0    65537    tariff 
   TABLE DATA           �   COPY public.tariff (tariff_id, tariff_name, period_price, minutes_balance_out, minutes_balance_in, minutes_balance_summary, minute_price_out, minute_price_in, expired_minute_price_out, expired_minute_price_in, currency) FROM stdin;
    public          postgres    false    214   ��       E           0    0    call_call_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.call_call_id_seq', 1, false);
          public          postgres    false    218            F           0    0    change_tariff_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.change_tariff_id_seq', 1, false);
          public          postgres    false    223            G           0    0    payment_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.payment_id_seq', 1, false);
          public          postgres    false    220            H           0    0    role_role_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.role_role_id_seq', 2, true);
          public          postgres    false    215            �           2606    65666    phone User_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.phone
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (user_phone);
 ;   ALTER TABLE ONLY public.phone DROP CONSTRAINT "User_pkey";
       public            postgres    false    217            �           2606    65679    call call_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY public.call
    ADD CONSTRAINT call_pkey PRIMARY KEY (call_id);
 8   ALTER TABLE ONLY public.call DROP CONSTRAINT call_pkey;
       public            postgres    false    219            �           2606    65722     change_tariff change_tariff_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.change_tariff
    ADD CONSTRAINT change_tariff_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.change_tariff DROP CONSTRAINT change_tariff_pkey;
       public            postgres    false    224            �           2606    65692    payment payment_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.payment DROP CONSTRAINT payment_pkey;
       public            postgres    false    221            �           2606    65628    role role_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (role_id);
 8   ALTER TABLE ONLY public.role DROP CONSTRAINT role_pkey;
       public            postgres    false    216            �           2606    65606    tariff tariff_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.tariff
    ADD CONSTRAINT tariff_pkey PRIMARY KEY (tariff_id);
 <   ALTER TABLE ONLY public.tariff DROP CONSTRAINT tariff_pkey;
       public            postgres    false    214            �           2620    65685    call call_trigger_func    TRIGGER     ~   CREATE TRIGGER call_trigger_func BEFORE INSERT ON public.call FOR EACH STATEMENT EXECUTE FUNCTION public.call_trigger_func();
 /   DROP TRIGGER call_trigger_func ON public.call;
       public          postgres    false    219    240            �           2620    65739 (   change_tariff change_tariff_trigger_func    TRIGGER     �   CREATE TRIGGER change_tariff_trigger_func BEFORE INSERT ON public.change_tariff FOR EACH STATEMENT EXECUTE FUNCTION public.change_tariff_trigger_func();
 A   DROP TRIGGER change_tariff_trigger_func ON public.change_tariff;
       public          postgres    false    227    224            �           2620    65713    payment payment_trigger_func    TRIGGER     �   CREATE TRIGGER payment_trigger_func AFTER INSERT ON public.payment FOR EACH STATEMENT EXECUTE FUNCTION public.payment_trigger_func();
 5   DROP TRIGGER payment_trigger_func ON public.payment;
       public          postgres    false    221    226            �           2620    65672    phone phone_trigger_func    TRIGGER     �   CREATE TRIGGER phone_trigger_func BEFORE INSERT OR UPDATE ON public.phone FOR EACH STATEMENT EXECUTE FUNCTION public.phone_trigger_func();
 1   DROP TRIGGER phone_trigger_func ON public.phone;
       public          postgres    false    217    241            �           2606    65667    phone User_tariff_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.phone
    ADD CONSTRAINT "User_tariff_id_fkey" FOREIGN KEY (tariff_id) REFERENCES public.tariff(tariff_id);
 E   ALTER TABLE ONLY public.phone DROP CONSTRAINT "User_tariff_id_fkey";
       public          postgres    false    214    3211    217            �           2606    65680    call call_user_phone_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.call
    ADD CONSTRAINT call_user_phone_fkey FOREIGN KEY (user_phone) REFERENCES public.phone(user_phone);
 C   ALTER TABLE ONLY public.call DROP CONSTRAINT call_user_phone_fkey;
       public          postgres    false    217    3215    219            �           2606    65733 .   change_tariff change_tariff_new_tariff_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.change_tariff
    ADD CONSTRAINT change_tariff_new_tariff_id_fkey FOREIGN KEY (new_tariff_id) REFERENCES public.tariff(tariff_id);
 X   ALTER TABLE ONLY public.change_tariff DROP CONSTRAINT change_tariff_new_tariff_id_fkey;
       public          postgres    false    224    3211    214            �           2606    65728 .   change_tariff change_tariff_old_tariff_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.change_tariff
    ADD CONSTRAINT change_tariff_old_tariff_id_fkey FOREIGN KEY (old_tariff_id) REFERENCES public.tariff(tariff_id);
 X   ALTER TABLE ONLY public.change_tariff DROP CONSTRAINT change_tariff_old_tariff_id_fkey;
       public          postgres    false    224    3211    214            �           2606    65723 +   change_tariff change_tariff_user_phone_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.change_tariff
    ADD CONSTRAINT change_tariff_user_phone_fkey FOREIGN KEY (user_phone) REFERENCES public.phone(user_phone);
 U   ALTER TABLE ONLY public.change_tariff DROP CONSTRAINT change_tariff_user_phone_fkey;
       public          postgres    false    224    3215    217            �           2606    65703 &   credential credentials_user_phone_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.credential
    ADD CONSTRAINT credentials_user_phone_fkey FOREIGN KEY (user_phone) REFERENCES public.phone(user_phone);
 P   ALTER TABLE ONLY public.credential DROP CONSTRAINT credentials_user_phone_fkey;
       public          postgres    false    217    3215    222            �           2606    65708 %   credential credentials_user_role_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.credential
    ADD CONSTRAINT credentials_user_role_fkey FOREIGN KEY (role_id) REFERENCES public.role(role_id);
 O   ALTER TABLE ONLY public.credential DROP CONSTRAINT credentials_user_role_fkey;
       public          postgres    false    3213    216    222            �           2606    65693    payment payment_user_phone_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_user_phone_fkey FOREIGN KEY (user_phone) REFERENCES public.phone(user_phone);
 I   ALTER TABLE ONLY public.payment DROP CONSTRAINT payment_user_phone_fkey;
       public          postgres    false    217    3215    221            5      x������ � �      :      x������ � �      8      x������ � �      7      x������ � �      3      x�m}IsI���W�mN�ڗ#WI\$~$G�i{���Q���B
���=�$20Ϭ��lU����e\FE��E]W�7ӯ����A�Q����:��(���ic���,>�6//A�#q��u\ge^�Ypc�M7nLxc�m�_��U�_ʋ"8[���ښ׃���H�%uZ�Q�y\�v՛�Kk�U�5����8��"�CE����it۶��T�y�o*�,�_X^���f��RU�U�'e��n��N_M?X�g���r,K_�3���s+�����M�iV&�šo����}c{�[금�<-�<�j����;{X���*-l �'8k]Ӆ�6v\��T��W����i{/�����e��q����5ve�{l��۾���)�s��Y\��.<w��\?n�G��,-���6���0�6|v;�5j��T&uR�Y��x��?���q��*���Uk�Ksy/�n�v��Cgq��I^ce̎{`«���I�*�4ʃ3.�
�����diT�E�Qp������q4G�-�O]�q�;���Q����>x�S�+�X����l�,]xg���=�x�,IҤ��$�6S���[�;��y�WQO�Y����`�Z��o�ئ(M,�Cc�ޅ��q��~a��*,`po�W�⍰Uc�s`�_̋���2�Xh��]����0+a���ӻv�s|�2�$�SWD�wk[��4l�OTY��a�W׹�1!v�L��ԙ����-�{�aǗ۷FYWZWu�T<�������(���]�8U�������v�M͋8���.�Y,�Ϧ�Ѽ��.�"Ə�ep�c��
qn��ax���������M#�=y�u�Ey�lDx�,7��3	�?+����[��Lk|I�ͧ1}
�g<<�Ov���<��8ˊ(
~���4�ކ��|3��V<��K��o�g��Hj,x
����n�����6�l����G���T��V�|"����>7�2�o\'y����݄����b�׮�*.�(�p~�+O��tj��:M�"�3�q�O��>W�b��K���E��Ҽ6+�ڌçu)�����{�1�i�^�����*���epi�
Q�ټ� ���oO`f�#N^x�H���S�&�!qU�f�p�۰P���a[U�[?�3�=�O�HE�Q����'s��WI���+?lX�_����:�FE���-»f�7���L�Q�$��q��ͧ��	�Z1|H|����Ɠ�e8F	�0��|��S��,F��A�����F��:���<���]c��^-�=��`ti	>����}�]��
>uQ0��Q<�7�so_�j�W�9�O�]?��l`)]���u�R�8�����H�k��q�˂/�9�O�����'&�qK8P<�-��=n2^�D�NqX�^�W<˕�;u��A�Rg���w�a�>���V8�5lvgG�#ȴ���1�V-�ӭp�v��-͊G��&�[��j�L?���Y	@����[���÷��,�M������wjq� &�[X&�/�o�N�1����h�=7���h�~�.�ڍD{0a�
�1�L��O�к7���ZB�j�F_����Ǵ��B�=�e���^A��-���R<��j���2pgR�=a�Z��5��_X�?��Rh��]xѻN�[�r��QS�N�qn�Ϊc]E�^���x�f=�g��%�n�m���X�������Qz�M?�p\�[��A�Lր���kZ�� �P0<$Ep�xh�X������@{���fje�}�^��Q�;�����߇eC�c�." �^����pm�] #�N	���������[�����8��GQJ�p1�8�ʙ�Q Jc�8�s����x�0၉�L�G;�
�	�휇҉�p�`��56d���:��
�&	Λ��#�m��J&4!r���y�_���{���£�a�cL��b�~��~q��{����6�u���[V� �1�N3­��;�E�����mY�k����˭�1�a�"�<o���\b�!�ags�� ar�|v����M�(����1���7۾� �ꄐ~`C<>�� ʙ���
h�G�O�-��?�%"V��s~�a7i�$F��`_]O���a�j��4M)���c��V��_�K <��e����x�>�VH��:�6���	��s*�/V���t�OS��Q�
$|6�1�����p�J��/�?d�s�� 2Ӷ_@io��8�82�0>�����e�(��ս�� �ϋ��#�bDW��8�kx�U��mY�w��\�%~k�z�*j�K��$>�%�I4�R~`����M��)z��!z��q�S?�_	�@�G�x�v���M�p�S��q�O{|�pF���[��Z�5��è�܍�<�?��Y�z4��a8��C[ovX @:D��j��(��>���n��2�����٬���C�z�T)��q����W.��[Xqp(l����30/Xp~�o�u�3���$,��b�0�8�L��N�z�:��k&�J#8�,'?�T�8�C��(4���Fp9�@:H��Zo/��&�4�n�o�7�)���!/�KDJ �g��Ծٟ���YU�ٿ�!W��fB<\ >�DGL>5��r��hg�N$�Æ��� �f8�i�g��l.Χ�IE�e��ol�#;,��F����S����3����0B������x�.�w뵇(	�"0ߒ眇��"��-�A�$4�Ƨq��B�q�NK&-�i���$|���W�1'#NĆz8&1hX�N�<bH�NI����i�V)`d��r��ABX�ے>��-@5  ��"[8���i� P��oΎ6:;J��GRXluق���n�mxO�9�\�_+�^��l�.A[	e��4��{�H^��A��U��nP��Ί��&9��H���a��d���	XoL�dM8��*��Kxz9��Yغºp�@��'��g�G�$��W���<UϽ{k< ��G��@��(	�3E��
:�k���v�����0Epm�mG��&���ʘߙ��=b+�%�ʌ�@
wV�8�i��:<�����.�� -U�`$�i�v[�x eF=��4�sL9�il@���if��㉙�3�{yV�3����p̚�W	��F�x��������h�7#x�9�C�b���@}S�XG	�q���جNbP*�LW3Z���~�Y��\��o7�?��d���_�*�u2�dݞ6�~�t��g6�h�Z1c���!Edv�j��
�I����{g<�8����7�EV�����ٽ��X~Op��<¿G��٘8/���5���I�)�^�3��	H���n&E���I�2�2l݅OS�X�q��Nb��8�m+Ĵ��F�1�?'���Fz/x��ۮj)B��ttc՘���_��^.��
��7ک�3򾋇�&���PH��ޏ"��,�0���L����\&_��z1�;���LT�GPy�ܓ�1�`Z@/ǓF@�5�����0��c��")�C�&\���"�O"Z��:	s<Ham�욥k��[pK�3�� ��4#k;�bHd�9b��JRw�����G�+`b� ������vuZ, �K h�@�h��Q*[TI�X��j�R��Z��`B�T$��V�O.
��;�������C9x/�/@�wNR�_{�⹾�V/�e�@#E���?!@*���!�l�N1��
�x�H�H�nf�3O�� L��i���فr$ L�#�i���� Qp'�$�6d�m�RE�<�F�e�0qT��ZŚ���R�όp/y "]K�A�,�5�g���k���V�̬�}X���L
|W���=��
�wT�P�)�,6��
�xw��Z�W+��o�?*'I�2<�<�=6�!�zk���1���$d�/vn�``���OL��`��u+����&�%Fh �u�� P&��
n��D��U��I^�����    uӻ��ī���!�!�^p��G��� a��,�t���S���l�� I�	�VК�$Z�Ѐ�5DCg����F��7�d��w�����Z��"�!�;�����E�z1Ʋ F3A>B��a�q�,H ۔f�xc�]�(b�A!��a�,0�{?�C��KXY�R��:|+���)��H� ���o��zjA�?������S�w\�W~��c���s�.�����I���dbF7ڥ���(�g�hA�m� ���}��h0���s��P1A��K�'^��� �|*�\ �և������ዅU�h��{����1�b$���e99<6{瓸��\jELK(�1��W�M�l��|t�R��K&5b�d���q�'u���?�[*K<�L0���� ���Z�E��I�R�Rӛ��KN�TsTi\g�/��΀Grmt�
�*2&Vi�p6�ݡS 4f�)�S8��f���M�H�{uН���f��6aΔ�D?E�[�3��Ν��х��O����W�=$1��`�B�>2%k�ʃ�p�L�=
�a<������P�3W�5�u�KX��'�}Y�kz�V�=avπ���ipV^]��V����
w�Ӥ4��R������?x>"�A�Y���/��S���6/r���U'�]~�G�p}b����sY�+�Ѧ�&vo�U]܈{	���8 g�+��{W_�1���p�s��,�H��I��$�+z�tJ ? �
D~�^��	x ����Sv<�n<���@��{���?���H��������@�5�>�-Go�3�)+�k�dЏ�F�0r������t�X�[;����I- �_�Rx*��PN`H4�ɉ��5�])�P�D����� �x">(�����������/����
�Ǝ#"��Md}Pu��(��� b^�W��'	¨be/���ۜ�!�H�S5��[����iFҟcS9*fa��.��I�(fZ6����RN����7�c�0�h���N8TEҋ�F��x�2P��YK�Ty��y��Dᒤ��ᵾ���� @Eq�G�K���|f]��������S�g^^���o���4�����H}�@����`n�#����V+{��$(�~�P���5�W#���� 1���b�j�Z?���U�X��k	�U�;��1Ti���٩�<˔5<�m8�,�`��f�I�@�-@�IK��xKM�I�  �$�sn�������XT�rOب�}ɬ(��f�^�(~�m(��oZ@<��Y�K��T|�@]�5İ�,xp�;qk?	��-�\���_ᇆ:�P3΂/,�\��*�U9�6���1l�[j��5�� ``��>o��'� h�f��cz�qME��/f*�cȻ�6�*����c���'�5�a��"�b��*�w�u5`�1�)3{����Ҽ�P1��#0�^���Q+Pb��[*5�������Z;�|�Å�';8�A��C���/P��	�逸�}Rؖ�P�8
ؚ^���Aa�K`�ִ-Ijԯl���%��R	�:��`oTНbXt~ņ�O;k�a</�*ό�fA��8�L�lZ-�!A��@D�T?{�7+�����Ѻ7�ܨ`�2<T 8�d^
�����Ձi��8m?�R��({S�"B�F�u�$2;�� ����,�}5��p%`[�����k��}kd]�H��}��Ұ&�#	L�4��S*�Oji`��l�H/�WNOo�9�����<)g�� r�/�a�^W�; $� έ<�g���P_R�G���?��G��3�����f�&%�֘�K������ �"���>[�B�Z:��M{R���FL&�̙��Ji�\�􌼢@�@:p"��F���ă�N=�3V�H���f�#"a�y&fV��z�
8D_|��`ßV]^�6���
M@�W	���R�&�@�ܨ�l�_�����a�$�)�� c����,�:�	NI<Q%T#nX���mO�D9�<5�g�+����t'�}���t�z��p/�'?�����^f�������#M�*{�J;�k��m%�k�ﱚ=1TR��K+�x��F�P�6���z�\'l2���r7 �x��$R���P����4C��HŊ")�<�g��v�7���Gr&�Sc`$x6����������m�K�_	{�(j!`��Ӓ�y�8�%�D\�Kۿ��� jP]�ew�HMpT�Ͱ�C�	Ŏ�⽧= �W����<��Ɔ޿L�m��ƛ�Cy�[� �3�[Ti�H2R�*g�莮ݠ�ev,ec�������8)a�pU����3�M�.�T�s��ϳ�S2L����}�5�T1�$�����ȗ@�����r�p�9?O���vZ4K��)I��!ጙ�j)�S���Dy�����݉�%gH��w���8�b7Pv~���I�Ҽ�j>� u��m�ͤja�h�(�edm�om��5����l�pp���fr�Q�������b��e=��s�qN��)�xB,���E����*VO�|1��0�����Q�����I�n�c9��
��;��4� o7�E9qD���ߜ�Y�J�`�~�����I}�*��E?��nO"���IAțլ8>�I�oCk��ĺf	y-�}xcۭ�8oL�d�r7P�s�'�(J./������/À{�)���c{���D���'s9`d�X��(����1�څ��	�.����O 0����?����ή�G�%�N)q2�&`�{���v[�b@���f>���	�[����/@��Q�N|�P�ƥXWx1:j�MvDx��Fq��d���E���'HJ������wR�V�]F�R�m$
��4��0�h�6���z0�������J�B�K�v<���i�*"�;�YE�	Y54'��:���v�ޤq���IDL��?�YYU�+����.8�-�F���DEGD60�o>��@J�:���L�1˯�����FB8K�J�T������h��+|�5��AĔ Wpc�'��8,9t�nA�M0<c7��Lf}Y5�v@58n+ݤU��"�J,a�@�@�EL�<ˡн��ʹ�c��[e��D%�l���n`&�;�-�E�$-���ջ4��;)��Y�쀨�'l�4rx!��9��P�0���?�K*�l�m{��l�R|y��G�;�K�����'X^��~���U�v�[IA<��VT������R������p���B�7R�*���F����j�Iq�sVJ���`�f��#�=xpX>�����Sg�����)��~�W�	�7����|0��$�S$�h�D3���f>�� O����⹡��P%�OkE�-?c*��H)K�S�$1gl�NՏ���*%U��6g8�p %��./DH8��������l�J��ڄ7I����� )? �*T�0R0��f#�!�Xi�s������C��Xs�	���#����o?)�UpN�`XK��Yamg3S�*U�p}���D�s,gb��h�#͂�0�qTU�,���ԷF1Ǟj���f)�'��+�§mÍ��/����<GЂ��gjT�&�\��{�˂��J��L:Zc�*�X�fl��ي�8���%{q�Dt��(�6�$�O89�X�Z�~5(�9�>�~`�������5�%ec߭��ל���ޱ�l�~�R���9-b�W�R%��г޻�i��0��΋���k�[��L�
�T����Sg�[)���ZE$�#�5��P&Ҁņ10S��3���(����2���'���'���F6(��v��;vY�� �(q�9���R�
vH�/��[
��`5 a��j�%_�؃$�hv�P)�A%4E�Y@�5��w�;nu�Ȉh�����n8����W	\v���¿����#�v�n�/L�2~JF�*֗R�䔯Lݦi��M�[� ��ٗ6wY��f�,ի!���QE�9���j'�/a�+O�2ٿ�Z�ʪ�����N`/;z@�?_�    E8��G�@F�̺�
�3�Ds��8n9�^�$�<��t��\�7*|��a�s��/3��*��v;���S�Ct�cTeE�I�>K[��%al|��s�'�����/c����_��I�b]�*�z������n�z.��9��Ig�����#��i�GL�(8P���c���^������d���ݴ�b^D؜F��w�@��DL��l�����E)Ht���rV�S�+��ò�a��x>6��c�΢�f;���k�,�X^Bel*�O�2�}��J�����a���@D�i;�����y� ,m���l�QEI6��5�0�H��4nĪa���댍�l�G���������#�|o�N�&i
lP-�]Z�{�����I���V��*��@�Ic������a��Yss&+�d9���y�6*�VS��I���3�FY�7���M�<BP���a�վ�j�w���H�g�Y�����_xV	b�<���_fsQON`]�6�E�N.��2�"�*ӂ�u�^x�U�Q�3(�Ψ�!�fr_"r�O����+�4��~u`���eL�!'�@h�33�w���� �(#y4X<�ә���8J%r��,qo�t���'I��O�~q�(L)�T�w�Mx|����|��rg�W�r��D��YT
7�����8<I��T ���!ވed�uA���>�̜S�9Q9��z�\ۨ�8�f��k�ȁ]��qip7-�J]G��Ҕ�*f��'��J�Z�d��HӚNT�LcofRr��;F�$��X$J�a��Qr6��1�W
���N������$5�Hz�Zf���u��K���[��;��}hjl((M\�?M�Ք�/�Ï���S���iU@�C\Q[�$D��.���Y�~q����Ƈ�YJ�Q�����<�>�.��+�g]�#�I|Ep��X��#m�wz+���I]c�|e��<�~"��Q��78�6�f o��\d"�c��Ղ��4��X���A�B8b�����D)�	�i�՜��Ґdt�!. ���q���K�1aZW;�j�$�g�8�!#֛#6��mD��kzϪR�&
vF��{�xŭ��~!�0�������{Ǯԍ�G$d2/�-G�u�xn&�.��7�7Ħ�i=�!Z�Q�>6x��⢷�H�9�m����ʀ4%��6-�����K=֏��v�N's�*��B
ꗤ��i霪?ǒ��)?fP�K�}��f�/��8P"z�䒲��1�B@>����aiH(G�ϴ9�*C�	�-��#�>O��JØ�cq<gU��}��?{�3-D� j�5ųW�{��:��Wɽ�d�ҥ��BE%R�4!�6�$/����_�T7���ʾ�SJDI��z=m8�L��0X�8L�j����5+8��x���Z,�������젡�ܰH�۝�,aJ2�bƌ��0)�z
��B��uf!r��H%GO�8b:�y�{r��ɘ+KJ:-��k�J�	K_�O ɼw��VEI,j�vXl񷡁9�O�{�$��.k�쉡d~ŢW�W]Ҭ�~��<��S��zVL��;��w�/*�MWl搱sl�%�;���%���Ǹ�MӪO�q���>���۪��)� ݅���?�XzzٌcҪ�5�6���r�j�*��<��~�o���Z2�
��{�dN�P�iIF�ޤ%QG,�q�EU?V�d�?��X% a�2ɩ�z~;0�f��8^0��Y�_�=��L|*����=�w�Z+�[w�8 �O) ˥�	G:�8��{�X�{����!���V�{6$|�T�Іߺ5P�;�=�X�.�J+I/��b�V�Ǟ����Zf�52 �o4~d7>�1h�φqnp��p,ڸ<���!��t�6��n�g3�o��ձ�o��,u^�(��˾a�����*���(�{k��}LQ�9)�%����_}�KY�1���
�9�jG��!���In��~韞8�9�$f����rz��A~P�f?{x��3k-�V0�� ��JS�N�����
�¿z�J�Ǝ<��5l<xޘߢ�m�VA�~PZI�fr�M��X�s�a�������I9�����rЙ�ԟh���p���sumz���K"�$e�ʶN�@��Ʈ�]fY�!x��Afǀ�U�dꌙ�Rf4�i��F�Z��qR%5,s�L��U�L�f[�����,=�[ͫ��(�H���!��۶�yc�@�cT��("��G*x�8b��l��?���^��c�-�^ş=�F�<U�)J#�e��d�8(N�?��$x�>7'It*O�#��&�8_߻+����}�q�����x�`���]��za��u5���b:��ט�Q<����ާyL��.�"Cݸ��H<��y�؈<k(��v8�j�U%�د��s`����}�?)]�~�
N��B$�ZsT�׬��2�0�Y�uZ�2�3h�;˺�Y�ְ�C�l�yo"�?#˶��9:x)�kd����u��3Be���h'U�>���~��o���up��Ƀ'�:N(��F�����6{۪�cdJ�G�㎌Ɨ���s��(G��j�tK%��I"c�8��ac��^��M�2���Bf���]��k�D ��Pk0X�(��D�M��_m�leF�I�h5�f6	~����V�*f'EM�}p��x>
�{�=�����NDWiDr~��pD35j���f�O U28��Γ�����OV���a�C�u�HZx8&���pg7�%���p�8�	���J+,��GU����VX��qC��j�'�J9�|>�wt�2�"ӽ��}��
�H���El I�Ld���[N-T�X&�$������󺎑0�O��L&�حL��^5��qr$�M���#]��Da�.P� ���KO"���NC�c�\�m�K���b
d���3�s�š�U+���5=����vv�����ĦQ���i�츾f��ˢT�)DK�'[��L,�����~�F�����dCN�`	����18p�cV�t2v�]�)Y	�q��ں��Ɇ��^�8�$�|���)�q�yQ�u����n�K��c���5�����8��뿸�]�b�Jœʇ�vu�~�;(C�K㔗G�EۼQ{)��$6��]�z�pA� ڐ�4+ �5�K��/c[+Sk93�O�m��9&	QV�ߒIu{�������+9�R4k��x�ߪv�P� �P����Wة?�-B�D *em#��u�	�+�$���`�l��{Ui����/?�NJ	j�� 
�k#�1���C���sz��͟��}�C���q(���c�sˍn��8�%�@I(���$U20���:ʋ�k?Zh�aB��^=��CYA�S1�5b����F� ���i���`�G9[ƴ���4I�Ι��+ls�~�ku��Í�'ɓ� -��i.53�QEi��̃���z�QGQ��R*@T_���<J����XXl��Q�Ql�W'"�2ޟ)�Okz��?�a�G� ����Ҽ2��j���=���v��r���4�ܒ�$��~/�D��t�:�V�Ji��r��+�>Gܒ�f��m��lT���D���4�u��ԟ�\Ա���ZO�[s�q��: &$�1N�9iڋ٫���=ە�����(�����<D�%#�-�Id�a�I&�u�y>�2z��;������HNN�TC�(a��=3��5k���I����)!�E���YI;�	C�,.���黒W~����3�+i�� �۪�*s��-|��Y����`r��|��#�S�sf)��#�"H����k�1cN#f�@��������N9�|G��2EBK�t�,S�?t���I/r���EČ@ ��`���� (���bn7T�,"���r�r!e2���DX�8����^�XF;��(8(^FЌT�"o��±d*��cL��n� {"�xg+!y�O��t	7�����7}�8�T\n����z6�CR�"D����L�O2�y-�BM`X��hwFj'#�(��Ȓ��]��s_��#�p�QD&%�J2;��    ��6�"�'E����HV��lL[����⋞�O1����8��ܽ��#f�9�!�lMd]M���\�j΢P�?����Z5�7��#���H�k�t�U`�$�ġ��17>��[�T�-5T���>4�(�EN��<#�mD�4�c�T̐�?k�)�Ԡ�t��DBWq�C%8k�3|g{��]��5v~�6KՅ��w��^�1��O��/��3�W�����MP��Y�-<n���$��G���βB��S�iUp��]�3?��k����f���a7�B�F�?QG�40��:�
�U4�USWy�����xO6��O�g@����cx��n�T�"����I����v���;��D�w�(b�jfN�D�S�	B��Id�9^�LX5�5�_'�w��/D������Y{"0H�Vq>1���l��VK�)��嘽Eo�N,wfu:8P&��~�e�'Z���/.��l�Ϫv�6�,L�A�QĮ���(��(Q	�-%# 8����c�~�=5�~XW�T�9/ܪWf4R��q��hv�nL=�>��0��d��9��P��q��Ԁ�\@�r �.���U�bް�{�Tъµ��v�ڰ=f���'�1�L��	Z҃��T��3f@�E��j���Hd�.-�!�	&[ۘ��(�!ڀa�^�Չ������ץmߌR��TQ���u�a�i�����ZĲ������5�'*`�wI���41�9l���]�IJ�?z=�7�8��d[���1Gװ�VR�~)����><k�@�{�tÜ�JYp4k'G�o,ǝ)_�91��Ϲ*f�LK�U Q��9=�_�x��k��e�[�9V�I8�>��O�����\#��
g���u�nܨCp���ԻE�u�F-s�9���ض�:��G=bA�,K��6��#g��a�x/#UX���@�U�Bʮ�L�؊�i8,���*��8��nv��(��*f��_��=�>l����Ǽ�E`s����qHtN/(�0�@=���:ڙ� 5�d􃌲؈��Ǚld�'}9���lv��$�	K'!��5��;=��̔Bql2#�����1)N�%��`�r�N]�D���{���آ��H���H�6��,Wݱ}ї�%���7VO�m���1�Ȉy�]�����6�R�"����ҽu>gf�'�t04�~�ΗZ����lPĶ�Fʹ�zZ� ��B��M��/4J�
Q�@�p��P.��턕^��I�Cp�4%�rK������ux��S����p�ifT�le@�r����}���Ks+�//�T��'�xW�i^y��}����Ԭ��sɿ;@p��g��sVy�.Si-�_eTx�L��~~�fj>/~(����۲;���EgW�fe�	�i�Z�հ���g8߰���RS�M��tbH�܀
�q�<SY.1�=�U�[�.�^�2U�d��s�i��p5��s�^��Y�18ݭ��6�5ʤ{��i%w��38�~�� ^A��eo�+�P�����qS�VJבֿ�~�X�V���ȐW���Yq�I���J�Η5���s�0�&��\�'�!d��5���IcU���}�Gэ���b�M)���sQ����㪔ˎN�r�����!�S�^7^i��ٙ.qvdV��o(�����
������H��f��{�k�{9�Hx�U,@˒5���:�l�Y�^A�[�w�t���j
V#N0�k��\�F�a:7F�{=k�衵dWgZ3��1���u�.��-d��40�©��xGN�A{l�ۆ2ғ�f�X!D�4Ԇ]R�?U�UyBfr��C�6[�ڪ�bب�m�Y�)��@iu�i��Nj��O4|{�3:�kD�w�O؞�pG���SDԏ�ahND�l�z�#���ɷ+�]EK��Rt��]y	g�r,�wż��f����Bx� 4%�9�X�{4�{���e���l�syF_ׅ7�%sp�4!!���L�� ٽ���'$��IM|�c8���2^��&�y� �-kV2����>x�i!��'Eb��c��2���\���|�T�_*u��x��S��'��2aś�f@b�E3/N�������<`0�٬T|`��l{�KK}ߜ n�Q'2։�B��@X}�+ɰ*���M���,��wC0!ܘ��]c�5F�ނ�s�'9�v|�G$Q˯sЄ�v^���q`5��FhZ�Ҹ�	9�����3�,�\�f˾%��_S�ʯ�e-m��_ܛ��/����Wm8��l�)&J�(��Vd�ik���YH�c/0%�VMm��V(�X�Y���agl�^c*��V�p�瓍�5��<r��m��^>��8>�(� �ǜyG���@�oLv5�'�!paD�U�ڨ=Q�D9N&�L.��	�7�r�z�0pn�09`Qos�BΔ�4�I[�_d}��'61��U܀����&!�X����r�23�y4�d
ԭEXU'��wd�, �}���&���c��Z���{B����2ل���ы���^�cUY}C�g;��;�q��6*��z?t��,�-{�6*��j1=m�5���X����K�:�N/���c�X��g�8 ,,�z5�CJ(֤D0s���ZY!�<޲z�:|`X5J��\f;<�5Q�C��
�b6'����F�p�8����InL�~i�����q�2��Q�{`3�8�A��5(��Wo�:UpTRS1qȨ��7:�P��H_�?��8�#�"��߯'mD2tr�r�@�si��Oܼ_ȩ�u���l�>�g2���k5uΥ�8�(�P�N����:HOZ)/�q)�\W���(��p�����ب�`Y��+c7��	�8%������8<���k�󳧚ED�ѣ����(�*N�&�)�h�?����Ӏ���
���j��U���7��yX<���f��zp@�����j��N�\����t�+^����}�wJ���l%���!�e�ꇀ�/+%�J��H�x��=(�3	�j7Nj��Tʪ-S��C��}
J�L�ȹ_t�[���S�ԋ"=������N��Z^���
8ra���*��Z��&2^�x�qʍte{�*�X
4��cJn���:�<��Β��(�����#^U̹�J2��7m�e��N*�d9X\F,��}$�J�A&�u��W@��wh)��Xdk�0��M��/c!�#"7��
��|7��L�0^N��]R��s.gf���`�K�C�79p��pQ�+Ǉ}�N�e AE��*s���$�>m6g�/�ȱ�:O{���2��T�3[8�Zn炉������O��7��Fʈ8<hݤ�SC��I��w3�k;m�%��2aZl�����^�ͬ��aS�Է�ٸ�&q�2w���e�g�[K�1�3���G1�� Yzo�Yd�'9�]��Z>�9
�g#JBiw E��w�Z�.-[�W�����:�J�NϾ�7 ����xA\Ns���H8\�E��q��S��+�̣U9��7;��i���p��
t��nR�'�T��m��2���1i��S�V�M�q��J&���WȽ���`ɋ�1�"��mQ�\���tF_��!��1K�yy�B���ˆ�9�,Gkt��f��Al�m���:��|%��sa��F���H9Q�z�xjd$Q(-�;nѻW׊#>n
XT�,Nl��oۏ�J=�\�u�cA�ZI�r��w��S��	��~ �\�MR�o�iN�$���P���=��s�Q&~�+V8����'�V>[،=
TV��=�R���c�ӫ��Jb���"̀�3�ϗ��:}o�倜�I�9K$�B�;3t�*&Q���G�^��o��8{w�I�VO|-��2����~Z�ߩ�V%g17+�I����|jxQ��7� 4��$S�s��u0*v�g��v���%^mH�d��]I*.ʛ��:eƛo���q�2�`���r��߮7�%��*f���)�}d���Z��<����y���W�����^�A���!u`��w�IJ`��7d�?o�\�N�<������3�����E�>	/̤�w z   ��N���;�e���Ner��`6�4��2�U_���hpp6���̍�5���)]f����q�|"c����.f�I�$�J���N:�)���*�.���Z=^é.c~�
�p,��{��������+We      2      x�3�,-N-�2��M�KL�b���� H��      0   T   x�30�����+-�ˬ�4@��z�`\T��e`��Z����Y�`l �3��1�҆@Rgh�韔��1�� h
�<��=... t�u     