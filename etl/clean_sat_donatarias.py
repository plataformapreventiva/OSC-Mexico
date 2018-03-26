import pandas as pd
import os
import re
from xlrd import xldate
import glob
import pdb

from dotenv import Dotenv

env_path = os.path.abspath('__file__' + "../../../../configs/.env")

rename_cols = {'RFC':'rfc',
                'ENTIDAD FEDERATIVA': 'entidad_federativa',
                'ACTIVIDAD O FIN AUTORIZADO':'actividad_autorizada',
                'DENOMINACIÓN O RAZÓN SOCIAL': 'razon_social',
                'DOMICILIO FISCAL': 'domicilio_fiscal',
                'OFICIO DE AUTORIZACIÓN':'oficio_autorizacion',
                'FECHA DE OFICIO': 'fecha_oficio',
                'OBJETO SOCIAL AUTORIZADO': 'objeto_social_autorizado',
                'REPRESENTANTE LEGAL': 'representante_legal',
                'NÚMEROS TELEFÓNICOS':'telefono',
                'E-MAIL': 'correo',
                'DOMICILIO DE ESTABLECIMIENTO ': 'domicilio_establecimiento',
                'DOMICILIO DEL ESTABLECIMIENTO ': 'domicilio_establecimiento',
                'NÚMEROS TELEFÓNICOS DEL ESTABLECIMIENTO': 'telefono_establecimiento',
                'ACREDITAMIENTO': 'acreditamiento',
                'ADMINISTRACIÓN LOCAL JURÍDICA': 'administracion',
                'ADMINISTRACIÓN DESCONCENTRADA DE SERVICIOS AL CONTRIBUYENTE': 'administracion'
            }

def find_figura_juridica(razon_social):
    """
    From the razon social find figura juridica associated
    if not assign 'otro'
    Args:
      razon_social (str): name of razon social
    """
    if razon_social:
        razon_social_clean = re.sub('[!@#$\.]', '', razon_social.lower())
        pattern = r'\b(ac|iap|sc|scp|abp|sa|iasp|fbp|iap|ibp|ia p|a c)\b'
        figura_juridica = re.findall(pattern, razon_social_clean)
        if figura_juridica:
            if figura_juridica[0] == 'a c':
                return 'ac'
            elif figura_juridica[0] == 'ia p':
                return 'iap'
            else:
                return figura_juridica[0]
        else:
            razon_social_clean = re.sub(r'[?.!"](?:\s|$)', '', razon_social.lower())
            razon_social_clean = re.sub('[!@#$\.\,]', '', razon_social_clean)
            figura_juridica = re.findall(pattern, razon_social_clean)
            if figura_juridica:
                return figura_juridica[0]
            else:
                return 'otro'
    else:
        return None

def clean_str_null(string_to_clean):
    if string_to_clean:
        if string_to_clean.lower() == 'no manifestó':
            return None
        else:
            return string_to_clean

def clean_sub(domicilio_sub):
    if domicilio_sub:
        pattern = r'\b(núm|num|blv|col|av|cp|lt|1era|2da|3era|seccion|s/n|mz|local|mun)\b'
        domicilio_sub_clean = re.sub(pattern, '', domicilio_sub)
        return domicilio_sub_clean.strip()

def direccion_dict(domicilio):
    d = dict()
    if domicilio:
        domicilio = re.sub('[!@#$\.-]', '', domicilio.lower())
        d_list = [x.strip() for x in domicilio.split(',') if x.strip()]
        d['calle'] = ''
        for d_sub in d_list[:-2]:
            colonia = re.findall(r'\b(col|colonia)\b', d_sub)
            cp = re.findall(r'\b(cp)\b', d_sub)
            if colonia:
                d['asentamiento'] = clean_sub(d_sub)
            elif cp:
                d['cp'] = clean_sub(d_sub)
            else:
                d['calle'] += clean_sub(d_sub)

        # Municipio
        d['municipio'] = clean_sub(d_list[-2])
        # estado
        d['entidad'] = clean_sub(d_list[-1])
    return d


def clean_and_append_all(prefix, input_path, output_path):
    # Read csv
    files = glob.glob('{path}/{prefix}_*.csv'.format(path=input_path,
                                                     prefix=prefix))
    df_all = pd.DataFrame()
    # loop through all files
    for f in files:
        print(f)
        year_base = re.findall('\d+', os.path.basename(f))
        if year_base:
            df = pd.read_csv(f)
            # Remove empty rows
            df = df[df['RFC'].notnull()]
            # Rename columns
            df.rename(columns=rename_cols, inplace=True)
            del df['administracion']
            df['year_autorizadas'] = str(year_base[-1])
            df_all = df_all.append(df)

    # Find tipo social
    df_all.reset_index(inplace=True)
    del df_all['index']
    df_all['figura_juridica'] = df_all['razon_social'].map(find_figura_juridica)
    # Fix date
    df_all['fecha_oficio'] = df_all['fecha_oficio'].apply(lambda x: xldate.xldate_as_datetime(x,0))

    # Clean null values
    df_all['domicilio_fiscal'] = df_all['domicilio_fiscal'].map(clean_str_null)
    df_all['domicilio_establecimiento'] = df_all['domicilio_establecimiento'].map(clean_str_null)
    df_all['telefono'] = df_all['telefono'].map(clean_str_null)
    df_all['correo'] = df_all['correo'].map(clean_str_null)
    df_all['telefono_establecimiento'] = df_all['telefono_establecimiento'].map(clean_str_null)

    # Split direccion
    df_all['domicilio_fiscal_d'] = df_all['domicilio_fiscal'].map(direccion_dict)
    geo_df = df_all['domicilio_fiscal_d'].apply(pd.Series)
    df_all = df_all.merge(geo_df, how='left', left_index=True, right_index=True)
    del df_all['domicilio_fiscal_d']

    df_all.to_csv(output_path + '/' + prefix + '_clean.csv', index=False)

if __name__ == "__main__":
    vals = Dotenv(env_path)
    input_path = vals['LOCAL_RAW']
    prefix = 'sat_donatarias'
    output_path = vals['LOCAL_CLEAN']
    clean_and_append_all(prefix, input_path, output_path)
